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

Puppet::Type.type(:dns).provide(:dns) do
    desc "Provider for management of DNS for Oracle Solaris"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

    Dns_fmri = "svc:/network/dns/client"

    mk_resource_methods

    def self.instances
        props = {}
        svcprop("-p", "config", Dns_fmri).split("\n").each do |line|
            fullprop, value = line.split(" ", 3).values_at(0,2)
            prop = fullprop.split("/")[1].intern
            props[prop] = value \
                if Puppet::Type.type(:dns).validproperties.include? prop
        end

        props[:name] = "current"
        props[:ensure] = :present

        # remove escaped spaces, they are invalid in the resource output
        props[:options] = props[:options].gsub(/\\ /,' ') if props[:options]
        return Array new(props)
    end

    Puppet::Type.type(:dns).validproperties.each do |field|
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
                fail "value: #{should.inspect}\n#{detail}\n"
            end
        end
    end

    def flush
        svccfg("-s", Dns_fmri, "refresh")
    end
end
