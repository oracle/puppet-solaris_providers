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
        @property_hash[:ensure] == :present
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
      end
      return instances
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

    def create
        # commands will always begin with these args
        args = ["-s", @resource[:fmri]]

        if @resource[:property].include? "/"
            args << "setprop" << @resource[:property] << "="
            if type = @resource[:type] and type != nil
                args << "#{@resource[:type]}:"
            end


            args << munge_value(@resource[:value],@resource[:type] ? @resource[:type] : type)
        else
            args << "addpg" << @resource[:property] << @resource[:type]
        end

        # Normal defined command execution doesn't work here in the case of
        # list type variables e.g.  svccfg: Invalid "net_address" value ...
        Puppet::Util::Execution.execute([command(:svccfg),*args].join(" "))

        svccfg("-s", @resource[:fmri], "refresh")
        update_property_hash
    end

    def destroy
        if @resource[:property].include? "/"
            svccfg("-s", @resource[:fmri], "delprop", @resource[:property])
        else
            svccfg("-s", @resource[:fmri], "delpg", @resource[:property])
        end
        svccfg("-s", @resource[:fmri], "refresh")
        update_property_hash
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
