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

Puppet::Type.type(:zfs_acl).provide(:solaris) do
  Ace = Puppet::Type::ZfsAcl::Ace
  desc "Provider for management of ZFS ACLs for Oracle Solaris"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11']
  commands :chmod => '/usr/bin/chmod', :ls => '/usr/bin/ls'

  mk_resource_methods

  def self.initialize(value={})
    super(value)
    @property_flush = {}
  end


  # Scan the owner@, group@, and everyone@ entries to see if they
  # contain the default set of perms exclusive of read/write/execute



  def exists?
    # return true immediately if we have already set :ensure
    return true if @property_hash[:ensure] == :present

    # Because we don't actually implement instances
    # populate the property_hash here
    @property_hash[:acl] = acl
    @property_hash[:ensure] = :present
    @property_hash[:file] = @resource[:file]
    @property_hash[:set_default_perms] ||= has_default_perms?(acl)
    return true
  rescue Puppet::ExecutionFailure
    @property_hash[:ensure] = 'absent'
    return false
  end

  def self.instances
    # We don't attempt to fetch all files to read their ACLs
    # but we need to define instances for puppet resource
    []
  end

  def insync?
    return false if @resource[:set_default_perms] == true && has_default_perms?
    super
  end

  def acl
    return @property_hash[:acl] if @property_hash[:acl] &&
                                   ! @property_hash[:acl].empty?

    line_expr = %r(^\d+:|^/|^:)

    entries = ls("-d", "-v", @resource[:file])
                .each_line
                .each_with_object([]) do |line,arr|
      line.strip!
      # Skip any unexpected lines
      next unless lmatch = line.match(line_expr)

      # lines which begin with a number are the start of an ACE
      if $& =~ /^\d+:/
        arr.push("")
        arr[-1] = lmatch.post_match
      else
        arr[-1] << line
      end
    end

    entries.each_with_object(@property_hash[:acl]=[]) do |ace,arr|
      arr.push(
        Puppet::Type::ZfsAcl::Ace.new(
          Puppet::Type::ZfsAcl::Ace.split_ace(ace),
          @resource
        )
      )
    end
  end

  def acl=(value)
    args=[@resource[:file]]

    if @resource[:set_default_perms] == true
      value = add_default_perms(value)
    end

    # we are always doing this
    if @resource[:purge_acl]
      str="A="
      str << value.map { |ace| ace.to_s }.join(",")
      args.unshift str
    end

    chmod(*args)

    # Refresh the ACL; a change was made
    @property_hash[:acl] = [] && acl
  end

  def create
    self.acl= @resource[:acl]
    return nil
  end

  def destroy
    # Removes all fine grained ACEs from the resource replacing them with
    # the set of ACEs which represent the current mode of the file and the
    # default set. e.g. leaves read, write, execute removes everything else
    chmod("A-", @resource[:file]) if has_custom_perms?
  end

  # by default check the defined resource for default # permissions; exists?
  # calls this with the existing acl
  def has_default_perms?(acl=@resource[:acl])
    owner =Ace::Util.default_perms['owner'].dup
    group = Ace::Util.default_perms['group'].dup
    everyone = Ace::Util.default_perms['everyone'].dup

    # Walk each ACE reduce the set of defaults for each
    # perms array with matches in discovered set
    acl.each do |ace|
      next unless ace.perm_type == 'allow'
      case ace.target
      when "owner@"
        owner = owner - ace.perms
      when "group@"
        group = group - ace.perms
      when "everyone@"
        everyone = everyone - ace.perms
      end
    end

    # If the set is empty all default perms are
    # currently set
    (owner + group + everyone).empty?
  end

  def has_custom_perms?
    # Check if a file has anything other than read_data, write_data,
    # or execute permissions in addition to the custom set

    # Walk each ACE reduce the set of defaults for each
    # perms array with matches in discovered set
    acl.each do |ace|
      perms = ace.perms.dup - ['read_data', 'write_data', 'execute']

      case ace.target
      when /:/
        # Any target with : is custom return true
        # immediately
        return true
      when "owner@"
        # Owner additionally gets append_data in the default set
        perms = perms - (Ace::Util.default_perms['owner'] + ['append_data'])
      when "group@"
        perms = perms - Ace::Util.default_perms['group']
      when "everyone@"
        perms = perms - Ace::Util.default_perms['everyone']
      end

      # Stop at the first ACE with custom permissions
      return true if not perms.empty?
    end
    return false
  end

  def add_default_perms(value=@resource[:acl])
    owner_found = false
    group_found = false
    everyone_found = false


    _acl = []
    _default = []
    # Add the default permission set to the first acl entry for owner, everyone and group
    value.each do |ace|
      unless ace.perm_type == 'allow'
        _acl.push(ace)
        next
      end
      case ace.target
      when "owner@"
        owner_found = true
        ace.perms=(ace.perms + Ace::Util.default_perms['owner']).uniq
        _default[0] = ace
      when "group@"
        group_found = true
        ace.perms=(ace.perms + Ace::Util.default_perms['group']).uniq
        _default[1] = ace
      when "everyone@"
        everyone_found = true
        ace.perms=(ace.perms + Ace::Util.default_perms['everyone']).uniq
        _default[2] = ace
      else
        _acl.push ace
      end
    end

    # Order here is also important or it will never match the default
    unless owner_found
      _default[0] = Ace.new({ 'target' => 'owner',
                              'perms' => Ace::Util.default_perms['owner'], 'perm_type' => 'allow' },
                            provider)
    end
    unless group_found
      _default[1] = Ace.new({ 'target' => 'group',
                              'perms' => Ace::Util.default_perms['group'], 'perm_type' => 'allow' },
                            provider)
    end
    unless everyone_found
      _default[2] = Ace.new({ 'target' => 'everyone',
                              'perms' => Ace::Util.default_perms['everyone'], 'perm_type' => 'allow' },
                            provider)
    end

    # Replace the ACL with our updated version
    _acl + _default
  end
end
