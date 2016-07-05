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

Puppet::Type.type(:interface_properties).provide(:interface_properties) do
    desc "Provider for managing Oracle Solaris interface properties"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :ipadm => '/usr/sbin/ipadm'

    def initialize(value={})
        super(value)
        @ifprops = {}
    end

    def self.instances
        props = {}

        ipadm("show-ifprop", "-c", "-o",
              "IFNAME,PROPERTY,PROTO,CURRENT").split("\n").collect do |line|
            ifname, property, proto, value = line.strip().split(":")
            fullname = ifname + "/" + proto
            if not props.has_key? fullname
                props[fullname] = {}
            end
            props[fullname][property] = value
        end

        interfaces = []
        props.each do |key, value|
            interfaces << new(:name => key,
                              :ensure => :present,
                              :properties => value)
        end
        interfaces
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

    def properties
        @property_hash[:properties]
    end

    def properties=(value)
        value.each do |key, val|
            ipadm("set-ifprop", "-p", "#{key}=#{val}", @resource[:name])
        end
    end

    def exists?
        if @resource[:properties] == nil
            return :false
        end

        ifname, protocol = @resource[:interface].split("/")

        @resource[:properties].each do |key, value|
            p = exec_cmd(command(:ipadm), "show-ifprop", "-m", protocol,
                         "-p", key, "-c", "-o", "CURRENT", ifname)

            if p[:exit] == 1
                Puppet.warning "Property '#{key}' not found for interface
                                #{ifname}"
                next
            end

            if p[:out].strip != value
                @ifprops[key] = value
            end
        end

        return @ifprops.empty?
    end

    def create
        name, proto = @resource[:interface].split("/")
        @ifprops.each do |key, value|
            ipadm("set-ifprop", "-m", proto, "-p", "#{key}=#{value}", name)
        end
    end

    def exec_cmd(*cmd)
        output = Puppet::Util::Execution.execute(cmd, :failonfail => false)
        {:out => output, :exit => $CHILD_STATUS.exitstatus}
    end
end
