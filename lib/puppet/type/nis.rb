#
#
# Copyright [yyyy] [name of copyright owner]
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

#
# Copyright (c) 2013, 2015, Oracle and/or its affiliates. All rights reserved.
#

require File.expand_path(File.join(File.dirname(__FILE__), '..','..','puppet_x/oracle/solaris_providers/util/validation.rb'))
require 'puppet/property/list'

Puppet::Type.newtype(:nis) do
    @doc = "Manage the configuration of the NIS client for Oracle Solaris"
    validator = PuppetX::Oracle::SolarisProviders::Util::Validation.new

    ensurable

    newparam(:name) do
       desc "The symbolic name for the NIS domain and client settings to use.
              This name is used for human reference only."
        isnamevar
    end

    newproperty(:domainname) do
        desc "The NIS domainname"
    end

    newproperty(:ypservers, :parent => Puppet::Property::List) do
        desc "The hosts or IP addresses to use as NIS servers.  Specify
              multiple entries as an array"

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

        validate do |value|
          unless validator.valid_ip?(value) || validator.valid_hostname?(value)
                raise Puppet::Error, "ypserver entry:  #{value} is
                    invalid"
          end
        end
    end

    newproperty(:securenets) do
        desc "Entries for /var/yp/securenets.  Each entry must be a hash.
              The first element in the hash is either a host or a netmask.
              The second element must be an IP network address.  Specify
              multiple entries as separate entries in the hash."

        def insync?(is)
            is = {} if is == :absent or is.nil?
            is.sort == self.should.sort
        end

        def should_to_s(newvalue)
          newvalue.to_s
        end

        def is_to_s(currentvalue)
          currentvalue.to_s
        end

        validate do |value|
          unless value.kind_of?(Hash)
            fail("Argument `#{value}`:#{value.class} is not a hash")
          end
          value.each_pair do |k,v|
            unless validator.valid_ip?(v)
              fail("Invalid address `#{v}` for entry `#{k}`")
            end
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
