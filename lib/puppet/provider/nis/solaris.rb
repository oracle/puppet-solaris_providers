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
# Copyright (c) 2013, 2015, Oracle and/or its affiliates. All rights reserved.
#

Puppet::Type.type(:nis).provide(:nis) do
    desc "Provider for management of NIS client for Oracle Solaris"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

    class << self; attr_accessor :client_fmri, :domain_fmri end
    Client_fmri = "svc:/network/nis/client"
    Domain_fmri = "svc:/network/nis/domain"

    def initialize(value={})
        super(value)
        @client_refresh = false
        @domain_refresh = false
    end

    def self.instances
        props = {}
        validprops = Puppet::Type.type(:nis).validproperties

        [Client_fmri, Domain_fmri].each do |svc|
            svcprop("-p", "config", svc).split("\n").collect do |line|
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
        end
        props[:name] = "current"
        return Array new(props)
    end

    # svc:/network/nis/client properties
    [:use_broadcast, :use_ypsetme].each do |field|
        define_method(field) do
            begin
                svcprop("-p", "config/" + field.to_s, Client_fmri).strip()
            rescue
                # if the property isn't set, don't raise an error
                nil
            end
        end

        define_method(field.to_s + "=") do |should|
            begin
                svccfg("-s", Client_fmri, "setprop", "config/" + field.to_s,
                       "=", '"' + should.to_s + '"')
            rescue => detail
                raise Puppet::Error,
                    "Unable to set #{field.to_s} to #{should.inspect}\n"
                    "#{detail}\n"
            end
            @client_refresh = true
        end
    end

    [:securenets].each do |field|
        define_method(field) do
            begin
                hash = {}
                val = svcprop("-p", "config/" + field.to_s, Domain_fmri).strip()
                arr = val.tr('\\', '').split(/ /)
                until arr == []
                  hash[arr[0]] = arr[1]
                  arr.shift
                  arr.shift
                end
                hash
            rescue
                # if the property isn't set, don't raise an error
                nil
            end
        end

        define_method(field.to_s + "=") do |should|
          arr = []
          if not should.empty?
            should.each do |key, value|
              arr.push('"' + key + " " + value + '"')
            end
            arr[0] = "(" + arr[0]
            arr[-1] = arr[-1] + ")"
          end
          svccfg("-s", Domain_fmri, "setprop",
                           "config/" + field.to_s, "=", arr)
        end
   end

    # svc:/network/nis/domain properties
    [:domainname, :ypservers].each do |field|
        define_method(field) do
            begin
                svcprop("-p", "config/" + field.to_s, Domain_fmri).strip()
            rescue
                # if the property isn't set, don't raise an error
                nil
            end
        end

        define_method(field.to_s + "=") do |should|
            begin
                if should.is_a? Array
                    # the first entry needs the open paren and the last entry
                    # needs the close paren
                    should[0] = "(" + should[0]
                    should[-1] = should[-1] + ")"

                    svccfg("-s", Domain_fmri, "setprop",
                           "config/" + field.to_s, "=", should)
                else
                    # Puppet seems to get confused about when to pass an empty
                    # string or "\"\"".  Catch either condition to handle
                    # passing values to SMF correctly
                    if should.to_s.empty? or should.to_s == '""'
                        value = should.to_s
                    else
                        value = "\"" + should.to_s + "\""
                    end
                    svccfg("-s", Domain_fmri, "setprop",
                           "config/" + field.to_s, "=", value)
                end
            rescue => detail
                raise Puppet::Error,
                    "Unable to set #{field.to_s} to #{should.inspect}\n"
                    "#{detail}\n"
            end
            @domain_refresh = true
        end
    end

    def flush
        if @domain_refresh == true
            svccfg("-s", Domain_fmri, "refresh")
        end
        if @client_refresh == true
            svccfg("-s", Client_fmri, "refresh")
        end
    end
end
