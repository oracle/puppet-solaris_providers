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

#XXX this is now ilb_server
Puppet::Type.type(:ilb_servergroup).provide(:ilb_servergroup) do
  @doc = "Provider to manage Solaris Integrated Load Balancer (ILB) server group configuration."
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :ilbadm => '/usr/sbin/ilbadm'

  mk_resource_methods

  def self.instances
    groups=Hash.new(Hash.new())

    ilbadm("show-servergroup","-o","all","-p").each_line do |line|
      name, sid, minp, maxp, ip = line.split
      groups=[name][sid] = {
        :ip => ip,
        :minp => (minp != '--' ? minp : nil),
        :maxp => (maxp != '--' ? maxp : nil),
      }
    end

    ilbadm("show-server","-o","servergroup,serverid,status","-p").each_line do |line|
      name,sid,status = line.split
      groups=[name][sid][:status] = status
    end

    return groups.each_pair.collect { |name,srv_hsh|
      server = srv_hsh.each_value.collect { |srv|
        # This could create a server resource to support
        # individually enabling/disabling servers in a more
        # granular way

        # Port is optional, build it up as needed
        port = ""
        if minp
          str << ":" << minp
          if maxp && maxp != minp
            str << "-" << maxp
          end
        end

        "%s%s" * [srv[:ip], port]
      }
      new(:name => name, :server => server.join(","), :ensure => :present)
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

  def create
    ilbadm("create-servergroup", "-s",
           "server=" << @resource[:server].join(","),
           @resource[:name])
    nil
  end

  def destroy
     ilbadm("delete-servergroup", @resource[:name])
     nil
  end

  def server=(value)
    unless (remove = server - @resource[:server]).empty?
      # is - should
      ilbadm("remove-server", "-s",
             "server=" << remove.join(","),
             @resource[:name])
    end
    unless (add = @resource[:server] - server).empty?
      # should - is
      ilbadm("add-server", "-s",
             "server=" << add.join(","),
             @resource[:name])
    end
    nil
  end
end
