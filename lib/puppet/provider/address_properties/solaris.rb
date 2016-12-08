#
# Copyright (c) 2013, 2014, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:address_properties).provide(:address_properties) do
    desc "Provider for managing Oracle Solaris address object properties"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :ipadm => '/usr/sbin/ipadm'

    mk_resource_methods

    def self.instances
        props = {}

        ipadm("show-addrprop", "-c", "-o",
              "ADDROBJ,PROPERTY,CURRENT,PERM").each_line do |line| 
            addrobj, property, value, perm = line.strip().split(":")
            # Skip read-only properties
            next if perm == 'r-'
            # Skip empty values
            next if (value == nil || value.empty?)
            if not props.has_key? addrobj
                props[addrobj] = {}
            end
            props[addrobj][property] = value
        end

        addresses = []
        props.each do |key, value|
            addresses << new(:name => key,
                             :ensure => :present,
                             :properties => value)
        end
        addresses
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

    # Return an array of prop=value strings to change
    def change_props
      out_of_sync=[]
      # Compare the desired values against the current values
      resource[:properties].each_pair { |prop,should_be|
        is = properties[prop]
        # Current Value == Desired Value
        unless is == should_be
          # Stash out of sync property
          out_of_sync.push("%s=%s" % [prop, should_be])
        end
      }
      out_of_sync
    end

    def properties=(value)
        @resource[:temporary] == :true ? tmp = "-t" : tmp = nil
        args = [change_props * ',', tmp].compact
        ipadm("set-addrprop", "-p", *args, @resource[:name])
    end

    def exists?
      @property_hash[:ensure] == :present
    end

    def create
      fail "address_object #{address} must exist"
    end
end
