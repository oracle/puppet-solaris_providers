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

Puppet::Type.type(:etherstub).provide(:etherstub) do
    desc "Provider for creating Solaris etherstubs"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :dladm => '/usr/sbin/dladm'

    def self.instances
        dladm("show-etherstub", "-p", "-o", "link").split(
              "\n").collect do |line|
            link = line.strip()
            new(:name => link, :ensure => :present)
        end
    end

    def add_options
        options = []
        if @resource[:temporary] == :true
            options << "-t"
        end
        options
    end

    def self.prefetch(resources)
        # pull the instances on the system
        etherstubs = instances

        # set the provider for the resource to set the property_hash
        resources.keys.each do |name|
            if provider = etherstubs.find{ |etherstub| etherstub.name == name}
                resources[name].provider = provider
            end
        end
    end

    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        dladm("create-etherstub", add_options, @resource[:name])
    end

    def destroy
        dladm("delete-etherstub", add_options, @resource[:name])
    end
end
