#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
#

require File.expand_path(File.join(File.dirname(__FILE__), '..','..','puppet_x/oracle/solaris_providers/util/validation.rb'))

Puppet::Type.newtype(:address_object) do
    @doc = "Manage the configuration of Oracle Solaris address objects"
    validator = PuppetX::Oracle::SolarisProviders::Util::Validation.new


    ensurable

    newparam(:name) do
        desc "The name of the address object or interface"
        isnamevar
    end

    newparam(:temporary) do
        desc "Optional parameter that specifies that the address object is
              temporary.  Temporary address objects last until the next reboot."
        newvalues(:true, :false)
    end

    newproperty(:address_type) do
        desc "The type of address object to create.  Valid values are static,
              dhcp, addrconf."
        # add from_gz and inherited as a valid values, even though users should not specify it
        newvalues(:static, :dhcp, :addrconf, :from_gz, :inherited)
    end

    newproperty(:enable) do
        desc "Specifies the address object should be enabled or disabled.
              This property is only applied temporarily, until next reboot."
        newvalues(:true, :false)
    end

    newproperty(:address) do
        desc "A literal IP address or a hostname corresponding to the local
              end-point.  An optional prefix length may be specified.  Only
              valid with an address_type of 'static'"

        validate do |value|
          unless validator.valid_ip?(value) || validator.valid_hostname?(value)
            raise Puppet::Error, ":address entry:  #{value} is invalid"
          end
        end
    end

    newproperty(:remote_address) do
        desc "A literal IP address or a hostname corresponding to an optional
              remote end-point.  An optional prefix length may be specified.
              Only valid with an address_type of 'static'"

        validate do |value|
          unless validator.valid_ip?(value) || validator.valid_hostname?(value)
            raise Puppet::Error, ":remote_address entry:  #{value} is invalid"
          end
        end
    end

    newproperty(:down) do
        desc "Specifies that the configured address should be marked down.
              Only valid with an address_type of 'static'."
        newvalues(:true, :false)
    end

    newproperty(:seconds) do
        desc "Specifies the amount of time in seconds to wait until the
              operation completes.  Only valid with an address_type of
              'dhcp'.  Valid values are a numerical value in seconds or
              'forever'"

        newvalues(/\d+/,"forever")
    end

    newproperty(:hostname) do
        desc "Specifies the hostname to which the client would like the DHCP
              server to map the client's leased IPv4 address.  Only valid
              with an address_type of 'dhcp'"

        validate do |value|
          unless validator.valid_hostname?(value)
            raise Puppet::Error, ":hostname entry:  #{value} is invalid"
          end
        end
    end

    newproperty(:interface_id) do
        desc "Specifies the local interface ID to be used for generating
              auto-configured addresses.  Only valid with an address_type of
              'addrconf'"
        # addr obj is something like <interface>/v4<optional string>
        newvalues(/\A\p{Alnum}+\/v[46](?:\p{Alpha}{0,})?\Z/)
    end

    newproperty(:remote_interface_id) do
        desc "Specifies an optional remote interface ID to be used for
              generating auto-configured addresses.  Only valid with an
              address_type of 'addrconf'"
        # addr obj is something like <interface>/v4<optional string>
        newvalues(/\A\p{Alnum}+\/v[46](?:\p{Alpha}{0,})?\Z/)
    end

    newproperty(:stateful) do
        desc "Specifies if stateful auto-configuration should be enabled or
              not."
        newvalues(:yes, :no)
    end

    newproperty(:stateless) do
        desc "Specifies if stateless auto-configuration should be enabled or
              not."
        newvalues(:yes, :no)
    end

    # If address_type is not supplied look for an incompatible set of
    # properties
    def check_implied_type_params
      invalid = []
      found = {
        :static => 0,
        :dhcp => 0,
        :addrconf => 0,
      }

      # List of all address_type properties
      @check_props = [:address,:remote_address,:down,:seconds,
        :hostname, :interface_id,:remote_interface_id]
      @check_props.freeze

      # Address types with acceptable properties
      @type_props = {
        :static => [:address,:remote_address,:down],
        :dhcp => [:seconds,:hostname],
        :addrconf => [:interface_id,:remote_interface_id],
        :from_gz => [],
        :inherited => []
      }
      @type_props.freeze

      # Set found = 1 for each type
      @type_props.each_pair { |k,v|
        v.each { |cp| found[k] = 1 if self[cp]
      }}

      # If more than one type is found the configuration is invalid
      if found.values.inject(0){ |s,a| s+= a } > 1
        invalid.push("incompatible property combination #{found.inspect}")
      end

      return invalid
    end

    def check_address_type_params(type)
      invalid = []

      # List of all address_type properties
      @check_props = [:address,:remote_address,:down,:seconds,
        :hostname, :interface_id,:remote_interface_id]
      @check_props.freeze

      # Address types with acceptable properties
      @type_props = {
        :static => [:address,:remote_address,:down],
        :dhcp => [:seconds,:hostname],
        :addrconf => [:interface_id,:remote_interface_id],
        :from_gz => [:bogus],
        :inherited => [:bogus]
      }
      @type_props.freeze

      # Select params which defined but invalid for the address_type
      invalid = @check_props.select { |cp|
        # Valid type if property is not found
        next unless @type_props[type].index(cp).nil?

        self[cp].nil? == false
      }


      # Return array of invalid options
      return invalid
    end

    # Validate generated resource as a whole
    validate {
      unless  self[:address_type]

        invalid = check_implied_type_params
        unless invalid.empty?
          fail("#{invalid[0]}. define :address_type for more details")
        end

      else

        invalid = check_address_type_params(self[:address_type])
        unless invalid.empty?
          fail("cannot specify #{invalid * ', '} with :address_type = #{self[:address_type]}")
        end


        case self[:address_type]
        when :dhcp
          fail("cannot specify :address with :address_type = :dhcp"
              ) if self[:address]
              fail("cannot specify :remote_address with :address_type = :dhcp"
                  ) if self[:remote_address]
                  fail("cannot specify :remote_address with :address_type = :dhcp"
                      ) if self[:remote_address]
        when :static
        when :addrconf
        when :from_gz, :inherited
          #fail("cannot specify any values with :address_type = #{self[:address_type]}")
        end
      end

    }
end
