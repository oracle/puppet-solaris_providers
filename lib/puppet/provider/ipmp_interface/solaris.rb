#
# Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:ipmp_interface).provide(:solaris) do
  desc "Provider for management of IPMP interfaces for Oracle Solaris"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :ipadm => '/usr/sbin/ipadm'

  mk_resource_methods

  def self.instances
    ifaces = []
    ipadm("show-if", "-p", "-o", "IFNAME,CLASS,PERSISTENT,OVER").each_line do |line|
      name, linkclass, persist, over = line.strip().split(":", 4)
      next if linkclass != "ipmp"
      ifaces << new(:name => name.strip(),
                    :ensure => :present,
                    :interfaces => over.split,
                    :temporary => persist =~ /^-+$/ ? :true : :false)
    end
    ifaces
  end

  def self.prefetch(resources)
    # pull the instances on the system
    ifaces = instances

    # set the provider for the resource to set the property_hash
    resources.keys.each do |name|
      if provider = ifaces.find{ |iface| iface.name == name}
        resources[name].provider = provider
      end
    end
  end

  def interfaces
    @property_hash[:interfaces]
  end

  def interfaces=(value)
    if temporary == :true
      # cannot modify temporary interfaces
      destroy
      create
      @property_hash[:interfaces] = value
      return value
    end
    remove_list = interfaces - value
    add_list = value - interfaces

    unless add_list.empty?
      ipadm("add-ipmp", '-i', add_list * ',', @resource[:name])
    end

    unless remove_list.empty?
      ipadm("remove-ipmp", '-i', remove_list * ',', @resource[:name])
    end
    return value
  end

  # If we are trying to change to/from temp recreate the interface
  def temporary=(value)
    destroy
    create
  end

  def add_options
    options = []
    if @resource[:temporary] == :true
      options << "-t"
    end
    options << "-i" << @resource[:interfaces] * ','
    options
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    ipadm('create-ipmp', *add_options, @resource[:name])
  end

  def destroy
    # Just remove any component interfaces
    ipadm("remove-ipmp", '-i', interfaces * ',', @resource[:name])
    ipadm('delete-ipmp', @resource[:name])
  end
end
