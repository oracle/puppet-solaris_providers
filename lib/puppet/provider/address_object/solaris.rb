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

Puppet::Type.type(:address_object).provide(:address_object) do
    desc "Provider for creating Oracle Solaris address objects"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :ipadm => '/usr/sbin/ipadm'

    mk_resource_methods

    def self.instances
        ipadm("show-addr", "-p", "-o", "addrobj,type,state,addr").split(
              "\n").collect do |line|
            addrobj, type, state, addr = line.split(":", 4)

            # replace any hypen with an underscore
            type = type.gsub(/\-/, "_")

            # look to see if this is a point-to-point address object
            if addr.include?("->")
                local, remote = addr.split("->")
                local = local.delete("\\")
                remote = remote.delete("\\")
            elsif type.downcase == "dhcp" and addr == "?"
                local = nil
                remote = nil
            else
                local = addr.delete("\\")
                remote = nil
            end

            down = :false
            if state == "ok"
                enable = :true
            elsif state == "disabled"
                enable = :false
            elsif state == "down"
                down = :true
                enable = :true
            end

            new(:name => addrobj,
                :ensure => :present,
                :address_type => type,
                :down => down,
                :enable => enable,
                :address => local,
                :remote_address => remote)
        end
    end

    def self.prefetch(resources)
        # pull the instances on the system
        addrobjs = instances

        # set the provider for the resource to set the property_hash
        resources.keys.each do |name|
            if provider = addrobjs.find{ |addrobj| addrobj.name == name}
                resources[name].provider = provider
            end
        end
    end

    def enable=(value)
        # only enable for temporary interfaces
        return unless temporary == :true
        if value == :true
            ipadm("enable-addr", "-t", @resource[:name])
        elsif value == :false
            ipadm("disable-addr", "-t", @resource[:name])
        end
    end

    def is_temp
        temp = []
        if @resource[:temporary] == :true
            temp << "-t"
        end
        temp
    end

    def down=(value)
        if value == :true
            ipadm("down-addr", is_temp, @resource[:name])
        elsif value == :false
            ipadm("up-addr", is_temp, @resource[:name])
        end
    end

    def add_options
        options = []
        if @resource[:temporary] == :true
            options << "-t"
        end

        if address_type = @resource[:address_type]
            options << "-T" << address_type
        end

        if address = @resource[:address]
            options << "-a" << "local=#{address}"
        end

        if remote_address = @resource[:remote_address]
            options << "-a" << "remote=#{remote_address}"
        end

        if @resource[:down] == :true
            options << "-d"
        end

        if seconds = @resource[:seconds]
            options << "-w" << seconds
        end

        if hostname = @resource[:hostname]
            options << "-h" << hostname
        end

        if interface_id = @resource[:interface_id]
            options << "-i" << "local=#{interface_id}"
        end

        if remote_interface_id = @resource[:remote_interface_id]
            options << "-i" << "remote=#{remote_interface_id}"
        end

        if stateful = @resource[:stateful]
            options << "-p" << "stateful=#{stateful}"
        end

        if stateless = @resource[:stateless]
            options << "-p" << "stateless=#{stateless}"
        end
        options
    end

    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        ipadm("create-addr", add_options, @resource[:name])
    end

    def destroy
        ipadm("delete-addr", @resource[:name])
    end
end
