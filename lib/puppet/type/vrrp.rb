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


require File.expand_path(
  File.join(File.dirname(__FILE__),
            '..','..','puppet_x/oracle/solaris_providers/util/validation.rb'))

Puppet::Type.newtype(:vrrp) do
  @doc = "Manage Solaris Virtual Router Redundancy Protocol (VRRP)
  configuration. See vrrpadm(8)

  **Note** To use VRRP you must install the vrrp package
  system/network/routing/vrrp and enable the vrrp service"

  validator = PuppetX::Oracle::SolarisProviders::Util::Validation.new

  ensurable

  newparam(:name, :namevar=>true) do
    desc "The name of a VRRP router. This name is used to identify a VRRP
               router in other vrrpadm subcommands.

               The maximum length of a valid router  name  is  31  characters.
               Legal  characters  are  alphanumeric  (a-z,  A-Z,  0-9) and the
               underscore ('_')."

    newvalues(/^[\p{Alnum}_]+$/)
    validate do |value|
      super(value)
      return false if value.length > 31
    end
  end

  newproperty(:temporary) do
    desc "Specifies  that  the  VRRP  router is temporary. Temporary VRRP
    routers last until the next reboot.
    Default: false"
    newvalues(/true/i,/false/i)
    defaultto :false

    munge do |value| value = value.downcase.intern end
  end

  newproperty(:enabled) do
    desc "Enable/Disable Router
      true        Router is enabled
      false       Router is disabled
      temp_true   Router is enabled until next reboot
      temp_false  Router is disabled until next reboot
    "
    newvalues(/(?:temp_)?(?:true|false)/i)
    munge do |value| value = value.downcase.intern end
  end


  newproperty(:router_type) do
    desc "VRRP router type. Either l2 or l3.
    Default: L2"
    defaultto :l2

    newvalues(/l2/i,/l3/i)

    munge do |value| value = value.downcase.intern end
  end

  newproperty(:adv_interval) do
    desc "The advertisement interval in  milliseconds.  Default  is  1000 (one
    second). The valid interval range is 10-40950."
    newvalues(/^\d+$/)

    munge do |value| value = value.to_i end

    validate do |value|
      super(value)
      unless (10..40950).include?(value.to_i)
        fail "Invalid value #{value} out of range 10-40950"
      end
    end
  end

  newproperty(:interface_name) do
    desc "The  interface  on  which  the VRRP router is configured. This
  determines the LAN this VRRP router is running in. For l2  VRRP router,  the
  interface can be a physical ethernet interface, a VLAN, or an aggregation.
  For l3 VRRP  router,  aside  from  the above  types, the interface can also
  be an IPMP interface, or a physical IB interface."
    newvalues(/^[\p{Alnum}_]+$/)

    validate do |value|
      super(value)
      unless (3..16).include?(value.length)
        fail "Invalid Value #{value} has unacceptable length (#{value.length}).
        min/max 3/16"
      end
    end

  end

  newproperty(:preempt) do
    desc "Flags: The  preempt  mode  controls whether an
  enabled higher priority backup router preempts a lower priority master
  router.
    See vrrpadm(8) for details.
    Default: true"
    defaultto :true
    newvalues(/(true|false)/i)
    munge do |value| value = value.downcase.intern end
  end

  newproperty(:accept) do
    desc "The accept mode controls the local  packet
  acceptance  of  the virtual  IP  addresses.
    See vrrpadm(8) for details.
    Default: true"
    defaultto :true
    newvalues(/(true|false)/i)
    munge do |value| value = value.downcase.intern end
  end

  newproperty(:priority) do
    desc "The priority of the specified VRRP router used in master selec-
      tion. The higher the value, the  greater  the  possibility  the
      router is selected as the master.

      The  default  value  is 255, which indicates the specified VRRP
      router is the IP Address Owner and  owns  all  the  virtual  IP
      addresses.

      The range 1-254 is available for VRRP routers backing up a vir-
      tual router.

      See vrrpadm(8) for details.
      Default: 255
    "
    defaultto 255
    newvalues(/^\d+/)

    munge do |value| value = value.to_i end

    validate do |value|
      super(value)
      unless (1..255).include?(value.to_i)
        fail "Invalid value #{value} out of range 1-255"
      end
    end
  end

  newproperty(:vrid) do
    desc "The virtual router identifier (VRID). Together with the address
    family, it identifies a virtual router within a LAN."
    newvalues(/^\d+$/)
    munge do |value| value = value.to_i end
  end

  newproperty(:assoc_ipaddrs, :array_matching => :all) do
    desc "The Array of associated virtual  IP  addresses  protected  by  the
    VRRP router in the form.  <ipaddr>[/<prefixlen>]>,
    <hostname>[/<prefixlen>], or 'linklocal'"

    validate do |value|
      super(value)
      return true if value == 'linklocal'
      _addr,_prefix = value.split('/',2)
      unless ( validator.valid_hostname?(_addr) || validator.valid_ip?(value) )
        fail "Invalid Value #{value} is not a vaild ip or hostname"
      end
      if _prefix && !validator.valid_ip?("0::0#{_prefix}")
        fail "Invalid Value #{_prefix} is not a vaild prefix length"
      end
    end
  end

  newproperty(:primary_ipaddr) do
    desc "The  IP  addresses configured over the <ifname> interface which
               can be potentially selected as the primary IP address  used  to
               send the VRRP advertisement."
    validate do |value|
      super(value)
      unless  validator.valid_ip?(value)
        fail "Invalid Value #{value} is not a vaild IP address"
      end
    end
  end
end
