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

Puppet::Type.type(:ip_interface).provide(:solaris) do
  desc "Provider for management of IP interfaces for Oracle Solaris"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11']
  commands :ipadm => '/usr/sbin/ipadm', :dladm => '/usr/sbin/dladm'

  def self.instances
    (dladm("show-link", "-p", "-o", "link").split("\n") &
     ipadm("show-if", "-p", "-o", "ifname").split("\n")).collect do |ifname|
      new(:name => ifname,
          :ensure => :present)
    end
  end

  def add_options
    options = []
    if @resource[:temporary] == :true
      options << "-t"
    end
    options
  end

  def exists?
    ipadm("show-if", "-p", "-o", "IFNAME").split(
      "\n"
    ).include? @resource[:name]
  end

  def create
    ipadm('create-ip', add_options, @resource[:name])
  end

  def destroy
    ipadm('delete-ip', @resource[:name])
  end
end
