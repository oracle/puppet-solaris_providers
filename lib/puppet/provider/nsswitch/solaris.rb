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

Puppet::Type.type(:nsswitch).provide(:nsswitch) do
    desc "Provider for name service switch configuration data"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

    class << self; attr_accessor :nsswitch_fmri end
    Nsswitch_fmri = "svc:/system/name-service/switch"

    def self.instances
        props = {}
        svcprop("-p", "config", Nsswitch_fmri).each_line.collect do |line|
            fullprop, type, value = line.split(" ", 2)
            pg, prop = fullprop.split("/")
            props[prop] = value \
                if Puppet::Type.type(:nsswitch).validproperties.include? prop
        end

        props[:name] = "current"
        return Array new(props)
    end

    Puppet::Type.type(:nsswitch).validproperties.each do |field|
        define_method(field) do
            begin
                out = svcprop("-p", "config/" + field.to_s,
                              Nsswitch_fmri).strip()
                out = out.delete("\\")
            rescue
                # if the property isn't set, don't raise an error
                nil
            end
        end

        define_method(field.to_s + "=") do |should|
            begin
                svccfg("-s", Nsswitch_fmri, "setprop",
                       "config/" + field.to_s, "=", '"' + should + '"')
            rescue => detail
                raise Puppet::Error,
                    "Unable to set #{field.to_s} to #{should.inspect}\n"
                    "#{detail}\n"
            end
        end
    end

    def flush
        svccfg("-s", Nsswitch_fmri, "refresh")
    end
end
