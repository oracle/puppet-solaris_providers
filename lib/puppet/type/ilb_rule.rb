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
require File.expand_path(File.join(File.dirname(__FILE__), '..','..','puppet_x/oracle/solaris_providers/util/ilb.rb'))
require 'ipaddr'

Puppet::Type.newtype(:ilb_rule) do
  @doc = "Manage Solaris Integrated Load Balancer (ILB) rule configuration.
  Existing rules cannot be modified they will be removed and re-created"

  validator = PuppetX::Oracle::SolarisProviders::Util::Validation.new

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name for the ilb rule"
  end

  newproperty(:enabled) do
    desc "Indicates if the rule should be enabled or disabled"
    newvalues(:true,:false)
  end

  #
  # Incoming Packet Spec
  #

  newproperty(:vip) do
    desc "(Virtual) destination IP address"

    validate do |value|
      fail "Invalid IP #{value}" unless validator.valid_ip?(value)
    end
  end

  newproperty(:port) do
    desc <<-HEREDOC
    Port number or name, for example, telnet or dns. A port can be
    specified by port number or symbolic name (as in /etc/services).
    Port number ranges are also supported 'port[-port]'.

    ** Note **
    The use of numerical ports is recommended. Service names are not
    validated at compilation time and may fail on individual nodes.
    HEREDOC

      validate do |value|
        PuppetX::Oracle::SolarisProviders::Util::Ilb.valid_portspec?(value)
      end

  end

  newproperty(:protocol) do
    desc "TCP (the default) or UDP (see /etc/services)."
    defaultto :tcp
    newvalues(:tcp,:udp)
  end

  newproperty(:persistent) do
    # It's not fully clear why one must use -p when using pmask, it's just what
    # it says in the docs
    desc "Create a persistent rule.
    When provided a pmask value this enables session persistence
    Default: false


    Pmask: The argument is a prefix length in CIDR notation; that is, 0–32 for IPv4 and 0–128 for IPv6.
    The larger the mask the more of the IP address is used to generate the session mapping.
    i.e. An IPv4 address has 32 bits
    "
    defaultto :false

    newvalues(:true,:false,%r(/\d+$))

    validate do |value|
      # Let newvalues check general input first
      super(value)
      next unless value.match(%r(/\d+$))
      fail "Invalid pmask #{value}" unless (0..128).include?(value.to_i)
    end
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

    validate do |value|
      ips = value.split('-')
      fail "Invalid IP range #{value}" if ips.length > 2
      ips.each { |ip|
        fail "Invalid IP #{ip}" unless validator.valid_ip?(ip)
      }
      if ips.length == 2
        if (range = (IPAddr.new(ips[0])..IPAddr.new(ips[1])).to_a.length) > 10
          fail "Invalid range > 10 addresses (#{range}) in range #{value}"
        end
      end
    end
  end

  newproperty(:servergroup) do
    desc "Specifies destination(s) for packets that match the criteria
    specified by the incoming packet spec. Specify a single server group as
    target. The server group must already have been created. Any matching
    ilb_servergroup resource will be auto required"
    newvalues(/^\p{Alnum}+$/)
  end

  #
  # Healthcheck
  #

  newproperty(:hc_name) do
    desc "Specifies the name of a predefined health check method"
    newvalues(/^\p{Alnum}+$/)
  end

  # With dependencies enforcing resource existence it may be possible
  # to check if this port is indeed valid in the server group
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
    newvalues(/^\d+$/)
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

  # Top level post parameter validation
  validate {
    # Skip validation if there is no catalog
    # i.e. puppet resource ilb_rule
    next if @cagtalog == nil
    [:vip, :port, :lbalg, :topo_type, :servergroup].each do |thing|
      fail("#{thing} must be defined") unless self[thing]
    end
  }

  autorequire(:ilb_servergroup) do
    [self[:servergroup]]
  end

  autorequire(:ilb_healthcheck) do
    [self[:hc_name]]
  end
end
