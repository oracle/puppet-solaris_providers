#
# Copyright (c) 2013, 2015, Oracle and/or its affiliates. All rights reserved.
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

require_relative '../../puppet_x/oracle/solaris_providers/util/svcs.rb'
require 'puppet/property/list'

Puppet::Type.newtype(:nis) do
  @doc = "Manage the configuration of the NIS client for Oracle Solaris"

  ensurable

  newparam(:name) do
    desc "The symbolic name for the NIS domain and client settings to use.
              Name can only be the literal value 'current'"
    newvalues("current")
    isnamevar
  end

  newproperty(:domainname) do
    desc "The NIS domainname"

    class << self
      attr_accessor :prop_type
    end
    self.prop_type = :hostname

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |value|
      is_hostname?(value,true)
    end
  end

  newproperty(:ypservers, :parent => Puppet::Property::List) do
    desc "The hosts or IP addresses to use as NIS servers.  Specify
              multiple entries as an array"

    class << self
      attr_accessor :prop_type
    end
    self.prop_type = :host

    include PuppetX::Oracle::SolarisProviders::Util::Svcs

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.to_a.flatten.sort == self.should.sort
    end

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |value|
      is_host?(value,true)
    end
  end

  newproperty(:securenets, :array_matching => :all) do
    # This cannot be a Puppet::Property::List as we build it by hand in
    # the provider when fetching instances
    desc "Array of array entries for /var/yp/securenets. Each entry must
        be an array.  The first element in the entry array is either 'host' or a
        netmask.  The second element must be an IP network address.  Specify
        multiple entries as additional arrays"

    class << self
      attr_accessor :prop_type
    end
    self.prop_type = :array

    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.sort == self.should.sort
    end

    def should_to_s(newvalue)
      newvalue.to_s
    end

    def is_to_s(currentvalue)
      currentvalue.to_s
    end

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |value|
      unless value.kind_of?(Array)
        fail("Argument `#{value}`:#{value.class} is not an array")
      end
      addr=value[1]
      addr << "/" << value[0] unless value[0] == 'host'
      unless is_net_address?(addr)
        fail("Invalid address `#{addr}` for entry `#{value}`")
      end
    end
  end

  newproperty(:use_broadcast) do
    desc "Send a broadcast datagram requesting needed bind information for
              a specific NIS server."
    newvalues(:true, :false)
  end

  newproperty(:use_ypsetme) do
    desc "Only allow root on the client to change the binding to a desired
              server."
    newvalues(:true, :false)
  end
end
