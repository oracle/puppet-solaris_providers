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

Puppet::Type.type(:interface_properties).provide(:interface_properties) do
    desc "Provider for managing Oracle Solaris interface properties"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :ipadm => '/usr/sbin/ipadm'

    mk_resource_methods

    def self.instances
      props = Hash.new { |k,v| k[v] = Hash.new { |k1,v1| k1[v1] = {} } }

        ipadm("show-ifprop", "-c", "-o",
              "IFNAME,PROPERTY,PROTO,CURRENT,DEFAULT").each_line do |line|
            ifname, property, proto, value, _default = line.strip().split(":")
            # IPMP group cannot be controlled, fwifgroup is also skipped
            next if proto == 'ip' && ['group','fwifgroup'].include?(property)
            value ||= :absent
            props[ifname][proto][property] = value
        end
        props.collect do |key, value|
          new(:interface => key,
                :ensure => :present,
                :properties => value,
               )
        end
    end

    def self.prefetch(resources)
        # pull the instances on the system
        props = instances

        # set the provider for the resource to set the property_hash
        resources.keys.each do |name|
            if provider = props.find{ |prop| prop.name == name}
                resources[name].provider = provider
            end
        end
    end

    def create
      fail "Interface must exist before properties can be set"
    end

    # Return a hash of property strings by protocol
    def change_props
      out_of_sync= Hash.new {|k,v| k[v]=[]}
      # Compare the desired values against the current values
      resource[:properties].each_pair { |proto,hsh|
        hsh.each_pair { |prop,should_be|
         is = properties[proto][prop]

          # Current Value == Desired Value
          unless is == should_be
            # Stash out of sync property
            out_of_sync[proto].push("%s=%s" % [prop, should_be])
          end
        }
      }

      out_of_sync
    end

    def properties=(value)
      change_props.each_pair { |proto,props|
        ipadm("set-ifprop",
              "-p", props * ",",
              "-m", proto,
              @resource[:name].split('/')[0] )
      }
      @property_hash[:properties].merge(value)
    end

    def exists?
      # Check only for the existence of the interface
      # insync is a question for later
      ! @resource[:properties].nil?
    end
end
