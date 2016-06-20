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

Puppet::Type.type(:boot_environment).provide(:boot_environment) do
    desc "Provider for Oracle Solaris Boot Environments (BEs)"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :beadm => '/usr/sbin/beadm', :zpool => '/usr/sbin/zpool'

    def self.instances
        beadm(:list, "-H").split("\n").collect do |line|
            data = line.split(";")
            name = data[0]
            if data[2].include? "R"
                activate = :true
            else
                activate = :false
            end

            new(:name => name,
                :ensure => :present,
                :activate => activate)
        end
    end

    def self.prefetch(resources)
        # pull the instances on the system
        bes = instances

        # set the provider for the resource to set the property_hash
        resources.keys.each do |name|
            if provider = bes.find{ |be| be.name == name}
                resources[name].provider = provider
            end
        end
    end

    def activate
        @property_hash[:activate]
    end

    def activate=(value)
        if value == :true
            beadm("activate", @resource[:name])
        end
    end

    def exists?
        @property_hash[:ensure] == :present
    end

    def build_flags
        flags = []

        if description = @resource[:description]
            flags << "-d" << "'#{description}'"
        end

        if clone_be = @resource[:clone_be]
            if clone_be.include? "@"
                if beadm(:list, "-H", "-s").split("\n").detect \
                    { |line| line.split(";")[1] == clone_be }
                        flags << "-e" << clone_be
                else
                    Puppet.warning "BE #{clone_be} not found.  Skipping -e
                                    argument."
                end
            else
                if beadm(:list, "-H").split("\n").detect \
                    { |line| line.split(";")[0] == clone_be }
                        flags << "-e" << clone_be
                else
                    Puppet.warning "BE #{clone_be} not found.  Skipping -e 
                                    argument."
                end
            end
        end

        if options = @resource[:options]
            options.each { |key, value| flags << "-o" << "#{key}=#{value}" }
        end

        if zp = @resource[:zpool]
            found = false
            for line in zpool(:list, "-o", "name", "-H").each_line do
                if zp == line.strip
                    found = true
                    flags << "-p" << zp
                end
            end
            if not found
                raise Puppet::Error, \
                    "Unable to create BE in zpool #{zp} -- #{zp} does not exist"
            end
        end
        flags
    end

    def create
        beadm(:create, build_flags, @resource[:name])
        if @resource[:activate] == :true
            beadm(:activate, @resource[:name])
        end
    end

    def destroy
        if beadm(:list, "-H", @resource[:name]).split(";")[2] =~ /N/
            Puppet.warning "Unable to destroy #{@resource[:name]} as it is 
                            the active BE."
        else
            beadm(:destroy, "-f", "-F", @resource[:name])
        end
    end
end
