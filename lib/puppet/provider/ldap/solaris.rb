#
#
# Copyright [yyyy] [name of copyright owner]
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

#
# Copyright (c) 2013, 2014, Oracle and/or its affiliates. All rights reserved.
#

Puppet::Type.type(:ldap).provide(:ldap) do
    desc "Provider for management of the LDAP client for Oracle Solaris"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

    Ldap_fmri = "svc:/network/ldap/client"

    def initialize(resource)
        super
        @refresh_needed = false
    end

    def self.instances
        if Process.euid != 0
            return []
        end
        props = {}
        validprops = Puppet::Type.type(:ldap).validproperties

        svcprop("-p", "config", Ldap_fmri).split("\n").collect do |line|
            data = line.split()
            fullprop = data[0]
            type = data[1]
            if data.length > 2
                value = data[2..-1].join(" ")
            else
                value = nil
            end

            pg, prop = fullprop.split("/")
            props[prop] = value if validprops.include? prop.to_sym
        end

        # attempt to set the cred/bind_passwd value
        begin
            props[:bind_passwd] = svcprop("-p", "cred/bind_passwd",
                                          "svc:/network/ldap/client").strip()
        rescue
            props[:bind_passwd] = nil
        end

        props[:name] = "current"
        return Array new(props)
    end

    Puppet::Type.type(:ldap).validproperties.each do |field|
        # get the property group
        pg = Puppet::Type.type(:ldap).propertybyname(field).pg
        define_method(field) do
            begin
                svcprop("-p", pg + "/" + field.to_s, Ldap_fmri).strip()
            rescue
                # if the property isn't set, don't raise an error
                nil
            end
        end

        define_method(field.to_s + "=") do |should|
            begin
                if should.is_a? Array
                    arr = should.collect {|val| '"' + val.to_s + '"'}
                    arr[0] = "(" + arr[0]
                    arr[-1] = arr[-1] + ")"

                    svccfg("-s", Ldap_fmri, "setprop",
                           pg + "/" + field.to_s, "=", arr)
                else
                    # Puppet seems to get confused about when to pass an empty
                    # string or "\"\"".  Catch either condition to handle
                    # passing values to SMF correctly
                    if should.to_s.empty? or should.to_s == '""'
                        value = should.to_s
                    else
                        value = "\"" + should.to_s + "\""
                    end
                    svccfg("-s", Ldap_fmri, "setprop",
                           pg + "/" + field.to_s, "=", value)
                end
                @refresh_needed = true
            rescue => detail
                raise Puppet::Error,
                    "Unable to set #{field.to_s} to #{should.inspect}\n"
                    "#{detail}\n"
            end
        end
    end

    def flush
        if @refresh_needed == true
            svccfg("-s", Ldap_fmri, "refresh")
        end
    end
end
