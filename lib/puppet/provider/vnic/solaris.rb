#
# Copyright (c) 2013, 2017, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:vnic).provide(:vnic) do
  desc "Provider for creating VNICs in the Solaris OS"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :dladm => '/usr/sbin/dladm'

  mk_resource_methods

  def self.instances
    vnics = []
    dladm("show-vnic", "-p", "-o", "link,over,macaddress").split(
      "\n").collect do |line|
      link, over, mac = line.split(":", 3)
      # remove the escape character
      vnics << new(:name => link,
                   :ensure => :present,
                   :lower_link => over,
                   :mac_address => mac.delete("\\"))
    end
    vnics
  end

  def self.prefetch(resources)
    # pull the instances on the system
    vnics = instances

    # set the provider for the resource to set the property_hash
    resources.keys.each do |name|
      if provider = vnics.find{ |vnic| vnic.name == name}
        resources[name].provider = provider
      end
    end
  end

  def lower_link=(value)
    dladm("modify-vnic", "-l", value, @resource[:name])
  end

  def mac_address=(value)
    dladm("modify-vnic", "-m", value, @resource[:name])
  end

  def add_options
    options = []
    if @resource[:temporary] == :true
      options << "-t"
    end

    if @resource[:mac_address]
      options << "-m" << @resource[:mac_address]
    end
    options
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    dladm('create-vnic', '-l', @resource[:lower_link], *add_options,
          @resource[:name])
  end

  def destroy
    dladm('delete-vnic', @resource[:name])
  end
end
