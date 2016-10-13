#
# Copyright (c) 2013, 2015, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:nis).provide(:nis) do
    desc "Provider for management of NIS client for Oracle Solaris"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

    class << self; attr_accessor :client_fmri, :domain_fmri end
    Client_fmri = "svc:/network/nis/client"
    Domain_fmri = "svc:/network/nis/domain"

    mk_resource_methods

    def self.instances
        props = {}
        validprops = Puppet::Type.type(:nis).validproperties

        [Client_fmri, Domain_fmri].each do |svc|
            svcprop("-p", "config", svc).split("\n").collect do |line|
                data = line.split()
                fullprop = data[0]
                if data.length > 2
                    value = data[2..-1].join(" ")
                else
                    value = nil
                end

                prop = fullprop.split("/")[1].intern
                props[prop] = value if validprops.include? prop.to_sym
            end
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

    # Return a string to pass to setrop ... = <string>
    def format_value(should)
                if should.is_a? Array
                    arr = should.collect {|val|
                      str = '"'
                      if val.kind_of? Array
                        str << val * ' '
                      else
                        str << val.to_s
                      end
                      str << '"'
                    }
                    arr.unshift "("
                    arr.push ")"

                    return arr * " "
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
                    return value
                end
    end

    # svc:/network/nis/client properties
    [:use_broadcast, :use_ypsetme].each do |field|
        # Don't define accessors, mk_resource_methods and instances pre-populate
        define_method(field.to_s + "=") do |should|
            begin
                svccfg("-s", Client_fmri, "setprop", "config/" + field.to_s,
                       "=", format_value(should) )
            rescue => detail
                fail "value: #{should.inspect}\n#{detail}\n"
            end
            @client_refresh = true
        end
    end

    # svc:/network/nis/domain properties
    [:securenets, :domainname, :ypservers].each do |field|
        # Don't define accessors, mk_resource_methods and instances pre-populate

        define_method(field.to_s + "=") do |should|
            begin
                    svccfg("-s", Domain_fmri, "setprop",
                           "config/" + field.to_s, "=", format_value(should))
            rescue => detail
                fail "value: #{should.inspect}\n#{detail}\n"
            end
            @domain_refresh = true
        end
    end

    def flush
            svccfg("-s", Domain_fmri, "refresh")
            svccfg("-s", Client_fmri, "refresh")
    end
end
