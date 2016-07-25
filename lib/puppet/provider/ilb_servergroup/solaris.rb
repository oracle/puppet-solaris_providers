#
# Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:ilb_servergroup).provide(:ilb_servergroup) do
  @doc = "Provider to manage Solaris Integrated Load Balancer (ILB) server group configuration."
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :ilbadm => '/usr/sbin/ilbadm'

  mk_resource_methods

  def self.instances
    ilbadm("show-servergroup","-o","sgname","-p").each_line.to_a.uniq.collect { |name|
      new(:name => name.strip, :ensure => :present)
    }
  end

  def self.prefetch(resources)
    _instances = instances
    resources.each_pair do |name|
      if provider = _instances.find { |_resource| _resource.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    # This creates an empty group ilb_server populates it
    ilbadm("create-servergroup", "-s", @resource[:name])
    nil
  end

  def destroy
     ilbadm("delete-servergroup", @resource[:name])
     nil
  end
end
