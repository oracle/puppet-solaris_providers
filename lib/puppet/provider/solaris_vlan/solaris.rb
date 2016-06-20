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
# Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved.
#

Puppet::Type.type(:solaris_vlan).provide(:solaris_vlan) do
    desc "Provider for creating Solaris VLANs"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :dladm => '/usr/sbin/dladm'

    def self.instances
        dladm("show-vlan", "-p", "-o", "link,over,vid").split(
              "\n").collect do |line|
            link, over, vlanid = line.split(":")
            new(:name => link,
                :ensure => :present,
                :lower_link => over,
                :vlanid => vlanid)
        end
    end

    def self.prefetch(resources)
        # pull the instances on the system
        vlans = instances

        # set the provider for the resource to set the property_hash
        resources.keys.each do |name|
            if provider = vlans.find{ |vlan| vlan.name == name}
                resources[name].provider = provider
            end
        end
    end

    def lower_link
        @property_hash[:lower_link]
    end

    def lower_link=(value)
        dladm("modify-vlan", "-l", value, @resource[:name])
    end

    def vlanid
        @property_hash[:vlanid]
    end

    def vlanid=(value)
        dladm("modify-vlan", "-v", value, @resource[:name])
    end

    def add_options
        options = []
        if @resource[:temporary] == :true
            options << "-t"
        end
        if @resource[:ensure] == :present and @resource[:force] == :true
            options << "-f"
        end
        options
    end

    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        dladm("create-vlan", add_options, "-l", @resource[:lower_link],
              "-v", @resource[:vlanid], @resource[:name])
    end

    def destroy
        dladm("delete-vlan", add_options, @resource[:name])
    end
end
