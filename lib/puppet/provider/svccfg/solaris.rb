#
# Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:svccfg).provide(:svccfg) do
  desc "Provider for svccfg actions on Oracle Solaris"
  defaultfor :operatingsystem => :solaris
  commands :svccfg => "/usr/sbin/svccfg", :svcprop => "/usr/bin/svcprop"


  include PuppetX::Oracle::SolarisProviders::Util::Svcs

  mk_resource_methods

  def exists?
    # Property groups are not displayed by svcprop
    # and thus do not have resources by default
    if is_pg_type?(@resource[:type])
      pg_exists?
    else
      @property_hash[:ensure] == :present
    end
  end

  def self.instances
    svcs = Hash.new {|h,k| h[k] = [] }
    # "prop_fmri" => [ "fmri", "property", "type", "value" ]

    svcprop('-a', '-f', '*').each_line do |line|
      if line.encode!(:invalid => :replace).match(/\Asvc:/)
        @prop_fmri = line.chomp.split[0]
        svcs[@prop_fmri] = line.chomp.split(%r(/:properties/| ),4)
      else
        # Handle multi-line properties
        svcs[@prop_fmri][-1] << line.chomp
      end
    end

    instances = []
    pgs = []
    pg_created = {}
    # Walk each discovered service
    svcs.each_pair do |prop_fmri,a|
      # Walk each property and create the resource
      instances.push new(
                       :name       => prop_fmri,
                       :prop_fmri  => prop_fmri,
                       :fmri       => a[0],
                       :property   => a[1],
                       :type       => a[2],
                       :value      => a[3],
                       :ensure     => :present,
                     )

      tmp_pg = prop_fmri.slice(0,prop_fmri.rindex('/'))
      unless pg_created.has_key? tmp_pg
        pgs.push new(
                   :name => tmp_pg,
                   :prop_fmri => tmp_pg,
                   :type => :unknown_pg,
                   :ensure => :present
                 )
        pg_created[tmp_pg]=true
      end
    end
    return instances + pgs
  end

  def self.prefetch(resources)
    things = instances
    resources.each_pair { |key,res|
      things.find { |prop|
        # Match on prop_fmri
        [
          res[:prop_fmri],
          # Try to construct a prop_fmri string
          "%s/:properties/%s" % [res[:fmri], res[:property]]
        ].include? prop.prop_fmri
      }.tap { |provider|
        next if provider.nil?
        resources[key].provider = provider
      }
    }
  end

  def update_property_hash
    if @resource[:prop_fmri] && !@resource[:prop_fmri].empty?
      a = svcprop('-f', @resource[:prop_fmri]).lines.first.split(/\s+/,3)
      @property_hash[:value] = a[2]
      @property_hash[:type] ||= a[1].to_sym
      @property_hash[:ensure] = :present
    else
      @property_hash[:ensure] = :absent
    end
  rescue
    @property_hash[:ensure] = :absent
  ensure
    return nil
  end

  # Strip the property to get the pg and check that it is a defined resource
  # or that it exists
  def pg(prop_fmri=@resource[:prop_fmri])
    prop_fmri.slice(0,prop_fmri.rindex('/'))
  end
  def pg_exists?
    return @pg_exists if @pg_exists
    svcprop(pg)
    @pg_exists = true
  rescue Puppet::ExecutionFailure
    @pg_exists = false
  end

  def value=(value)
    args = ["-s", @resource[:fmri], 'setprop', @resource[:property], '=']
    args << munge_value(
      @resource[:value],@resource[:type] ? @resource[:type] : type
    )
    svccfg(*args)
    svccfg("-s", @resource[:fmri], "refresh")
    update_property_hash
    return value
  end

  def create
    # commands will always begin with these args
    args = ["-s", @resource[:fmri]]

    # It is legal to create nested property groups. We no longer try to
    # guess intent with the presence of a /
    if is_pg_type?(@resource[:type])
      args << "addpg" << @resource[:property] << @resource[:type]
    else
      fail "Property Group (#{pg}) must exist" unless pg_exists?
      args << "setprop" << @resource[:property] << "="

      # Add resource type if it is defined
      if type = @resource[:type] and type != nil
        args << "#{@resource[:type]}:"
      end

      # Add munged value
      args << munge_value(@resource[:value],
                          @resource[:type] ? @resource[:type] : type)
    end

    svccfg(*args)
    svccfg("-s", @resource[:fmri], "refresh")
    update_property_hash
  end

  def destroy
    # delprop deletes either a property or the property group
    svccfg("-s", @resource[:fmri], "delprop", @resource[:property])
    svccfg("-s", @resource[:fmri], "refresh")
    @property_hash[:ensure] = :absent
    return nil
  end

  def delcust
    list_cmd = Array[command(:svccfg), "-s", @resource[:fmri], "listprop",
                     "-l", "admin"]
    delcust_cmd = Array[command(:svccfg), "-s", @resource[:fmri]]
    if @resource[:property] != nil
      list_cmd += Array[@resource[:property]]
      delcust_cmd += Array[@resource[:property]]
    end

    # look for any admin layer customizations for this entity
    p = exec_cmd(list_cmd)
    if p[:out].strip != ''
      # there are admin customizations
      if @resource[:property] == nil
        svccfg("-s", @resource[:fmri], "delcust")
      else
        svccfg("-s", @resource[:fmri], "delcust", @resource[:property])
      end
      svccfg("-s", @resource[:fmri], "refresh")
    end
    update_property_hash
  end

  def exec_cmd(*cmd)
    output = Puppet::Util::Execution.execute(cmd, :failonfail => false)
    {:out => output, :exit => $CHILD_STATUS.exitstatus}
  end
end
