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

Puppet::Type.type(:ldap).provide(:ldap) do
    desc "Provider for management of the LDAP client for Oracle Solaris"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

    Ldap_fmri = "svc:/network/ldap/client"

    mk_resource_methods

    def exists?
      @property_hash[:ensure] == :present
    end

    def self.instances
        if Process.euid != 0
          # Failure is presumed to be better than returning the empty
          # set. We expect Puppet needs to always run as root so this
          # may be moot outside of testing
          fail "LDAP configuration is not availble to non-root users"
        end
        props = {}
        validprops = Puppet::Type.type(:ldap).validproperties
        svcprop("-p", "config", "-p", "cred", Ldap_fmri).split("\n").collect do |line|
            data = line.split()
            fullprop = data[0]
            _type = data[1]
            if data.length > 2
                value = data[2..-1].join(" ")
            else
                value = nil
            end

            _pg, prop = fullprop.split("/")
            prop = prop.intern

            props[prop] = value if validprops.include? prop
        end

        props[:name] = "current"
        props[:ensure] = :present
        return Array new(props)
    end

    def self.prefetch(resources)
      # pull the instances on the system
      inst = instances

      # set the provider for the resource to set the property_hash
      resources.keys.each do |name|
        if provider = inst.find{ |i| i.name == name}
          resources[name].provider = provider
        end
      end
    end

    def create
      fail "Cannot create a new instance. Use the fixed name 'current'"
    end

    # Define getters and setters
    Puppet::Type.type(:ldap).validproperties.each do |field|
        next if [:ensure].include?(field)
        # get the property group
        pg = Puppet::Type.type(:ldap).propertybyname(field).pg

        # Don't define accessors, mk_resource_methods and instances pre-populate

        define_method(field.to_s + "=") do |should|
            begin
                if should.is_a? Array
                    arr = should.collect {|val| '"' + val.to_s + '"'}
                    arr.unshift "("
                    arr.push ")"

                    svccfg("-s", Ldap_fmri, "setprop",
                           pg + "/" + field.to_s, "=", arr * " ")
                else
                    # Puppet seems to get confused about when to pass an empty
                    # string or "\"\"".  Catch either condition to handle
                    # passing values to SMF correctly
                    if should.to_s.empty? or should.to_s == '""'
                        value = should.to_s
                    elsif should.match(/['"]/)
                        value = "\"" + should.to_s + "\""
                    else
                        value = should.to_s
                    end
                    svccfg("-s", Ldap_fmri, "setprop",
                           pg + "/" + field.to_s, "=", value)
                end
            rescue => detail
                fail "value: #{should.inspect}\n#{detail}\n"
            end
        end
    end

    def flush
            svccfg("-s", Ldap_fmri, "refresh")
    end
end
