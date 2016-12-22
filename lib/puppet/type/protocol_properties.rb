#
# Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.newtype(:protocol_properties) do
  @doc = "Manage Oracle Solaris protocol properties"

  ensurable do
    # remove the ability to specify :absent.  New values must be set.
    newvalue(:present) do
      provider.create
    end
  end

  newparam(:name) do
    desc "The name of the protocol"
    isnamevar
    newvalues(:dhcpv4,:dhcpv6,:icmp,:ip,:ipv4,:ipv6,
              :sctp,:tcp,:udp,
              # This is probably a non-exhaustive list so we allow any
              # alphanumeric string as well
              /^\p{Alnum}+$/)
  end

  newparam(:temporary) do
    desc "Optional parameter that specifies changes to the protocol are
              temporary.  Changes last until the next reboot.
              This parameter is ignored"
    newvalues(:true, :false)
  end

  newproperty(:properties) do
    desc "A hash table of propname=propvalue entries to apply to an
              protocol. See ipadm(8)"

    def insync?(is)
      # There will almost always be more properties on the system than
      # defined in the resource. Make sure the properties in the resource
      # are insync
      should.each_pair { |prop,value|
        return false unless is.has_key?(prop)
        # Stop after the first out of sync property
        return false unless property_matches?(is[prop],value)
      }
      true
    end

    validate { |hsh|
      fail "Invalid, must be a hash" unless hsh.kind_of? Hash
      fail "Invalid, cannot be empty" if hsh.empty?
      hsh.each_pair { |key,value|
        fail "key #{key} must be a-Z - _" unless key.match(/[\p{Alnum}_-]+/)
        fail "value #{value} must be a-Z - _" unless key.match(/[\p{Alnum}_-]+/)
      }
    }
  end
end
