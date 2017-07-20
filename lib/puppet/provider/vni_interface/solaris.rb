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

Puppet::Type.type(:vni_interface).provide(:solaris) do
  desc "Provider for management of VNI interfaces for Oracle Solaris"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :ipadm => '/usr/sbin/ipadm'

  def self.instances
    vnis = []
    ipadm("show-if", "-p", "-o", "IFNAME,CLASS").split(
      "\n"
    ).each do |line|
      ifname, ifclass = line.split(":", 2)
      next if ifclass != "vni"
      vnis << new(:name => ifname, :ensure => :present)
    end
    vnis
  end

  def add_options
    options = []
    if @resource[:temporary] == :true
      options << "-t"
    end
    options
  end

  def exists?
    p = exec_cmd(command(:ipadm), "show-if", "-p", "-o", "IFNAME,CLASS",
                 @resource[:name])
    if p[:exit] == 1
      return false
    end

    ifname, ifclass = p[:out].strip().split(":", 2)
    if ifclass == "vni"
      return true
    end

    # for all other cases, return false
    return false
  end

  def create
    ipadm('create-vni', add_options, @resource[:name])
  end

  def destroy
    ipadm('delete-vni', @resource[:name])
  end

  def exec_cmd(*cmd)
    output = Puppet::Util::Execution.execute(cmd, :failonfail => false)
    {:out => output, :exit => $CHILD_STATUS.exitstatus}
  end
end
