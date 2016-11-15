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

Puppet::Type.type(:link_properties).provide(:link_properties) do
    desc "Provider for managing Oracle Solaris link properties"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :dladm => '/usr/sbin/dladm'

    def initialize(value={})
        super(value)
        @linkprops = {}
    end

    def self.instances
        dladm("show-link", "-p", "-o", "link").
        split("\n").collect do |link|
            props = {}
            dladm("show-linkprop", "-c", "-o", "property,value",
                  link.strip()).split("\n").collect do |line|
                next if line.strip.end_with? ":"
                data = line.split(":", 2)
                name, value = data
                props[name] = value.delete("\\")  # remove the escape character
            end

            new(:name => link.strip(),
                :ensure => :present,
                :properties => props)
        end
    end

    def self.prefetch(resources)
        instances.each do |prov|
            if resource = resources[prov.name]
                resource.provider = prov
            end
        end
    end

    def properties
        @property_hash[:properties]
    end

    def properties=(value)
        dladm("set-linkprop", add_properties(value), @resource[:name])
    end

    def add_properties(props)
        a = []
        props.each do |key, value|
            a << "#{key}=#{value}"
        end
        properties = Array["-p", a.join(",")]
    end

    def exists?
        if @resource[:properties] == nil
            return :false
        end

        @resource[:properties].each do |key, value|
            p = exec_cmd(command(:dladm), "show-linkprop", @resource[:link],
                         "-c", "-p", key, "-o", "value")
            if p[:exit] == 1
                Puppet.warning "Property '#{key}' not found for link " \
                               "#{@resource[:link]}"
                next
            end

            if p[:out].strip != value
                @linkprops[key] = value
            end
        end

        return @linkprops.empty?
    end

    def create
        if @linkprops
            dladm("set-linkprop", add_properties(@linkprops), @resource[:link])
        end
    end

    def exec_cmd(*cmd)
        output = Puppet::Util::Execution.execute(cmd, :failonfail => false)
        {:out => output, :exit => $CHILD_STATUS.exitstatus}
    end
end

