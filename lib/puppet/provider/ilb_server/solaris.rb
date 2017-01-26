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

Puppet::Type.type(:ilb_server).provide(:ilb_server) do
  @doc = "Provider to manage Solaris Integrated Load Balancer (ILB) server configuration."
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :ilbadm => '/usr/sbin/ilbadm'

  mk_resource_methods

  def self.instances
    groups=Hash.new { |h,k| h[k] = {} }

    ilbadm("show-servergroup", "-o",
           "SGNAME,SERVERID,MINPORT,MAXPORT,IP_ADDRESS", "-p").
      each_line do |line|
      sgname, sid, minp, maxp, ip = line.strip.split(":",5)
      ip.insert(0,'[').insert(-1,']') if ip.index(':')
      groups[sgname][sid] = {
        # colons in IPv6 are esacped with \
        :ip => ip.tr('\\',''),
        :minp => (minp != '--' ? minp : nil),
        :maxp => (maxp != '--' ? maxp : nil),
        :ensure => :present,
        :enabled => :unassigned
      }
    end

    # Enabled/Disabled in only available for servers assigned to rules
    # Only entries assigned to rules are returned by show-server
    ilbadm("show-server","-o","servergroup,serverid,status", "-p").
      each_line do |line|
      sgname,sid,status = line.strip.split(":")
      groups[sgname][sid][:enabled] =
        if status == 'D'
          :false
        else
          :true
        end
    end

    servers=[]
    groups.each_pair do |sgname,srv_hsh|
      srv_hsh.each_pair.collect do |sid,srv|
        # Port is optional, build it up as needed
        port = nil
        if srv[:minp]
          port = srv[:minp]
          if srv[:maxp] && srv[:maxp] != srv[:minp]
            port << "-" << srv[:maxp]
          end
        end

        servers.push(new(
                       :name => [sgname,srv[:ip],port].join("|"),
                       :server => srv[:ip],
                       :port => port,
                       :servergroup => sgname,
                       :ensure => srv[:ensure],
                       :enabled => srv[:enabled],
                       :sid => sid
        ))
      end
    end
    return servers
  end

  def self.prefetch(resources)
    _instances = instances
    resources.keys.each do |name|
      if provider = _instances.find { |_resource| _resource.name == name }
        resources[name].provider = provider
      end
    end
  end

  def enabled=(value)
    # Use property sid, not resource. User cannot specify sid
    if value == :true
      ilbadm("enable-server", sid)
    elsif value == :false
      ilbadm("disable-server", sid)
    end
  end


  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    ilbadm("add-server", "-s", "server=#{@resource[:server]}:#{@resource[:port]}",
           @resource[:servergroup])
    nil
  end

  def destroy
    ilbadm("remove-server", "-s", "server=#{sid}",
           @resource[:servergroup])
  end
end
