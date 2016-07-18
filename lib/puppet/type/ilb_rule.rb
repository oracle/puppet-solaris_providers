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


require File.expand_path(File.join(File.dirname(__FILE__), '..','..','puppet_x/oracle/solaris_providers/util/validation.rb'))

Puppet::Type.newtype(:ilb_rule) do
  @doc = "Manage Solaris Integrated Load Balancer (ILB) rule configuration"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name for the ilb rule"
  end

  #
  # Incoming Packet Spec
  #

  newproperty(:vip) do
    desc "(Virtual) destination IP address"

    validation do |value|
      fail "Invalid IP #{value}" unless validation.valid_ip?(value)
    end
  end

  newproperty(:port) do
    desc "Port number or name, for example, telnet or dns. A port can be
      specified by port number or symbolic name (as in /etc/services).
      Port number ranges are also supported 'port[-port]'."
  end

  newproperty(:protocol) do
    desc "TCP (the default) or UDP (see /etc/services)."
    defaultto :tcp
    newvalues(:tcp,:udp)
  end

  newproperty(:test) do
    desc "UDP, TCP, external method (script or binary). An external method
      should be specified with a full path name."
      newvalues(:tcp,:udp,%r(^/.+))
  end

  newproperty(:default_ping) do
    desc "Execute default ping test before high layer health check tests.
    Default: true"
    defaultto :true
    newvalues(:true,:false)
  end

  newproperty(:persistent) do
    desc "Create the rule as persistent (sticky). The default is that
    the rule exists only for the current session (false).

    Optionally apply a pmask(stickiness). The argument is a prefix
    length in CIDR notation; that is, 0–32 for IPv4 and 0–128 for IPv6"
    defaultto :false
    newvalues(:false,:true,/\d\+/)
  end

  #
  # Handling Method
  #

  newproperty(:lbalg) do
    desc "The default is roundrobin, Other alternatives are: hash-ip,
    hash-ip-port, hash-ip-vip"
    defaultto :roundrobin
    newvalues(:roundrobin, :hash_ip, :hash_ip_port, :hash_ip_vip)
  end

  newproperty(:topo_type) do
    desc "Refers to topology of network. Can be DSR, NAT, or HALF-NAT"
    newvalues(:dsr,:nat,:half_nat)
  end

  newproperty(:proxy_src) do
    desc "Required for full NAT only. Specifies the IP address range
    to use as the proxy source address range. The range is limited to
    ten IP addresses."
  end

  newproperty(:servergroup) do
    desc "Specifies destination(s) for packets that match the criteria
    specified by the incoming packet spec. Specify a single server group as
    target. The server group must already have been created. Any matching
    ilb_servergroup resource will be auto required"
  end

  #
  # Healthcheck
  #

  newproperty(:hc_name) do
    desc "Specifies the name of a predefined health check method"
  end

  newproperty(:hc_port) do
    desc "Specifies the port(s) for the HC test program
    to check. The value can be keywords ALL or ANY, or a specific port number
    within the port range of the server group."
    newvalues(:all,:any,/^\d+$/)
  end

  #
  # Timers
  #

  newproperty(:conn_drain) do
    desc <<-HEREDOC
  If a server's type is NAT or HALF-TYPE, conn-drain is the timeout after which
  the server's connection state is deleted following the server's removal from
  a rule. This deletion occurs even if the server is not idle.

  The default for TCP is that the connection state remains stable until the
  connection is gracefully shutdown. The default for UDP is that the connection
  state remains stable until the connection has been idle for the period
  nat-timeout.
    HEREDOC
    newvalue(/^\d+$/)
  end

  newproperty(:nat_timeout) do
    desc <<-HEREDOC
    Applies only to NAT and half-NAT type connections. If such a connection is
    idle for the nat-timeout period, the connection state will be removed. The
    default is 120 for TCP and 60 UDP.
    HEREDOC
    newvalues(/^\d+$/)
  end

  newproperty(:persist_timeout) do
    desc "When persistent mapping is enabled, if a numeric-only mapping
    has not been used for persist-timeout seconds, the mapping will be
    removed. The default is 60."
    newvalues(/^\d+$/)
  end

  # XXX autorequire
end
