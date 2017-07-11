#
# Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Puppet::Type.type(:zone).provide(:solaris) do
  desc "Provider for Solaris zones."

  commands :adm => "/usr/sbin/zoneadm", :cfg => "/usr/sbin/zonecfg"
  defaultfor :osfamily => :solaris

  mk_resource_methods

  # Convert the output of a list into a hash
  def self.line2hash(line)
    fields = [:id, :name, :ensure, :zonepath, :uuid, :brand, :iptype ]
    properties = Hash[fields.zip(line.split(':'))]

    del_id = [:id, :uuid]

    # Configured but not installed zones do not have IDs
    del_id << :id if properties[:id] == "-"
    del_id.each { |p| properties.delete(p) }
    properties[:ensure] = properties[:ensure].intern

    properties
  end


  def self.instances
    adm(:list, "-cp").split("\n").collect do |line|
      new(line2hash(line))
    end
  end


  # Read in the zone configuration parameters and properties and
  # perform the zone configuration. Options are cloning the zone,
  # which needs a zonecfg_export file, configuring an archive, which
  # takes optional zonecfg_export and archived_zonename parameters,
  # or performing a zone configuration, which requires a zonecfg_export
  # file or string.
  def configure
    # make sure there's a zonecfg from some source
    if @resource[:zonecfg_archive].nil? && @resource[:zonecfg_export].nil?
      fail "No configuration resource is defined."
    end

    # open zonecfg_export as a file if possible or treat it like a string
    unless @resource[:zonecfg_export].nil? || @resource[:zonecfg_export].empty?
      begin
        file = File.open(@resource[:zonecfg_export], "rb")
        exported_cfg = file.read.gsub(/[\n]\n*\s*/, "; ")
      rescue
        exported_cfg = @resource[:zonecfg_export].gsub(/[\n]\n*\s*/, "; ")
      ensure
        file.close unless file.nil?
      end
    end

    # start building a command line
    command = "#{command(:cfg)} -z #{@resource[:name]}"

    # start building the subcommands
    command << " '"

    # use an archive if specified
    if !@resource[:zonecfg_archive].nil?
      # use the config from the archive
      command << "create -a #{@resource[:zonecfg_archive]}"

      # use an archived zone if specified
      if !@resource[:archived_zonename].nil?
        command << " -z #{@resource[:archived_zonename]}"
      end

      command << ";"
    end

    # use the exported zonecfg if specified
    if !@resource[:zonecfg_export].nil? and !exported_cfg.nil?
      command << " #{exported_cfg}"
    end

    # end the subcommands
    command << "'"

    # execute the command to configure the zone
    if command
      exec_cmd(:cmd => command)
    end
  end

  def destroy
    zonecfg :delete, "-F"
  end

  def exists?
    properties[:ensure] != :absent
  end

  # We cannot use the execpipe in util because the pipe is not opened in
  # read/write mode.
  def exec_cmd(var)
    if var[:input]
      execute("echo \"#{var[:input]}\" | #{var[:cmd]}", :failonfail => true, :combine => true)
    else
      execute((var[:cmd]).to_s, :failonfail => true, :combine => true)
    end
  end


  def install(dummy_argument=:work_arround_for_ruby_GC_bug)
    if ['5.11', '5.12'].include? Facter.value(:kernelrelease)
      if !@resource[:install_args] and @resource[:config_profile]
        @resource[:install_args] = " -c " + @resource[:config_profile]
      elsif !@resource[:install_args] and @resource[:archive]
        @resource[:install_args] = " -a " + @resource[:archive]
        if @resource[:archived_zonename]
          @resource[:install_args] << " -z " + @resource[:archived_zonename]
        end
      elsif @resource[:config_profile]
        @resource[:install_args] << " -c " + @resource[:config_profile]
      end
    end

    if @resource[:clone] # TODO: add support for "-s snapshot"
      if @resource[:config_profile]
        zoneadm :clone, @resource[:install_args].split(" "), @resource[:clone]
      else
        zoneadm :clone, @resource[:clone]
      end
    elsif @resource[:install_args]
      zoneadm :install, @resource[:install_args].split(" ")
    else
      zoneadm :install
    end
  end

  # Look up the current status.
  def properties
    if @property_hash.empty?
      @property_hash = status || {}
      if @property_hash.empty?
        @property_hash[:ensure] = :absent
      else
        @resource.class.validproperties.each do |name|
          @property_hash[name] ||= :absent
        end
      end
    end
    @property_hash.dup
  end

  # We need a way to test whether a zone is in process.  Our 'ensure'
  # property models the static states, but we need to handle the temporary ones.
  def processing?
    hash = status
    return false unless hash
    ["incomplete", "ready", "shutting_down"].include? hash[:ensure]
  end

  # Collect the configuration of the zone. The output looks like:
  # zonename: z1
  # zonepath: /export/z1
  # brand: native
  # autoboot: true
  # bootargs:
  # pool:
  # limitpriv:
  # scheduling-class:
  # ip-type: shared
  # hostid:
  # net:
  #         address: 192.168.1.1
  #         physical: eg0001
  #         defrouter not specified
  # net:
  #         address: 192.168.1.3
  #         physical: eg0002
  #         defrouter not specified
  #
  def getconfig
    output = zonecfg :info
    name = nil
    current = nil
    hash = {}
    output.split("\n").each do |line|
      case line
      when /^(\S+):\s*$/
        name = $1
        current = nil # reset it
      when /^(\S+):\s*(\S+)$/
        hash[$1.intern] = $2
      when /^\s+(\S+):\s*(.+)$/
        if name
          hash[name] ||= []
          unless current
            current = {}
            hash[name] << current
          end
          current[$1.intern] = $2
        else
          err "Ignoring '#{line}'"
        end
      else
        debug "Ignoring zone output '#{line}'"
      end
    end

    hash
  end

  def start
    # Check the sysidcfg stuff
    if ['5.10'].include? Facter.value(:kernelrelease)
      if cfg = @resource[:sysidcfg]
        self.fail "Path is required" unless @resource[:path]
        zoneetc = File.join(@resource[:path], "root", "etc")
        sysidcfg = File.join(zoneetc, "sysidcfg")

        # if the zone root isn't present "ready" the zone
        # which makes zoneadmd mount the zone root
        zoneadm :ready unless File.directory?(zoneetc)

        unless Puppet::FileSystem.exist?(sysidcfg)
          begin
            File.open(sysidcfg, "w", 0o600) do |f|
              f.puts cfg
            end
          rescue => detail
            puts detail.stacktrace if Puppet[:debug]
            fail "Could not create sysidcfg: #{detail}", detail.backtrace
          end
        end
      end
    end

    # Boots the zone
    zoneadm :boot
  end

  # Return a hash of the current status of this zone.
  def status
    begin
      output = adm "-z", @resource[:name], :list, "-p"
    rescue Puppet::ExecutionFailure
      return nil
    end

    main = self.class.line2hash(output.chomp)
    main
  end

  def ready
    # Prepare the zone
    zoneadm :ready
  end

  def stop
    # Shutdown the zone
    zoneadm :halt
  end


  def unconfigure
    # Unconfigure and delete the zone
    zonecfg :delete, "-F"
  end

  def uninstall
    # Uninstall the zone
    zoneadm :uninstall, "-F"
  end

  private

  def zoneadm(*cmd)
    # Execute the zoneadm command with the arguments
    # provided
    adm("-z", @resource[:name], *cmd)
  rescue Puppet::ExecutionFailure => detail
    self.fail Puppet::Error, "Could not #{cmd[0]} zone: #{detail}", detail
  end

  def zonecfg(*cmd)
    # You apparently can't get the configuration of the global zone (strictly in solaris11)
    return "" if self.name == "global"
    begin
      cfg("-z", self.name, *cmd)
    rescue Puppet::ExecutionFailure => detail
      self.fail Puppet::Error, "Could not #{cmd[0]} zone: #{detail}", detail
    end
  end
end
