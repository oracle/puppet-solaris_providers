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

Puppet::Type.type(:dns).provide(:dns) do
    desc "Provider for management of DNS for Oracle Solaris"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

    Dns_fmri = "svc:/network/dns/client"

    def self.instances
        props = {}
        svcprop("-p", "config", Dns_fmri).split("\n").each do |line|
            fullprop, _type, value = line.split(" ", 3)
            _pg, prop = fullprop.split("/")
            prop = prop.intern
            props[prop] = value \
                if Puppet::Type.type(:dns).validproperties.include? prop
        end

        props[:name] = "current"
        props[:ensure] = :present
        return Array new(props)
    end

    Puppet::Type.type(:dns).validproperties.each do |field|
        define_method(field) do
            begin
                svcprop("-p", "config/" + field.to_s, Dns_fmri).strip()
            rescue
                # if the property isn't set, don't raise an error
                nil
            end
        end

        define_method(field.to_s + "=") do |should|
            begin
                if should.is_a? Array
                    arr = should.collect {|val| '"' + val + '"'}
                    arr[0] = "(" + arr[0]
                    arr[-1] = arr[-1] + ")"

                    svccfg("-s", Dns_fmri, "setprop",
                           "config/" + field.to_s, "=", arr)
                else
                    # Puppet seems to get confused about when to pass an empty
                    # string or "\"\"".  Catch either condition to handle
                    # passing values to SMF correctly
                    if should.to_s.empty? or should.to_s == '""'
                        value = should.to_s
                    else
                        value = "\"" + should.to_s + "\""
                    end
                    svccfg("-s", Dns_fmri, "setprop",
                           "config/" + field.to_s, "=", value)
                end
            rescue => detail
                raise Puppet::Error,
                    "Unable to set #{field.to_s} to #{should.inspect}\n"
                    "#{detail}\n"
            end
        end
    end

    def flush
        svccfg("-s", Dns_fmri, "refresh")
    end
end
