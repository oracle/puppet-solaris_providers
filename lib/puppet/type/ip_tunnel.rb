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

Puppet::Type.newtype(:ip_tunnel) do
  @doc = "Manage the configuration of Oracle Solaris IP Tunnel links"

  ensurable

  newparam(:name) do
    desc "The name of the iptunnel link"
    isnamevar
  end

  newparam(:temporary) do
    desc "Optional parameter that specifies that the IP tunnel is
              temporary.  Temporary IP tunnels last until the next reboot."
    newvalues(:true, :false)
  end

  newproperty(:tunnel_type) do
    desc "Specifies the type of tunnel to be created."
    newvalues("ipv4", "ipv6", "6to4")
  end

  newproperty(:local_address) do
    desc "IP address or hostname corresponding to the local tunnel address"
  end

  newproperty(:remote_address) do
    desc "IP address or hostname corresponding to the remote tunnel address"
  end
end
