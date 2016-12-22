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

require_relative '../../puppet_x/oracle/solaris_providers/util/svcs.rb'
require 'puppet/property/list'


Puppet::Type.newtype(:dns) do
  @doc = "Manage the configuration of the DNS client for Oracle Solaris"

  newparam(:name) do
    desc "The symbolic name for the DNS client settings to use.  This name
              is used for human reference only."
    newvalues("current")
    isnamevar
  end

  newproperty(:nameserver, :parent => Puppet::Property::List) do
    desc "The IP address(es) the resolver is to query.  A maximum of
              3 IP addresses may be specified.  Specify multiple IP addresses
              as an array"

    def should
      @should
    end
    class << self
      attr_accessor :prop_type
    end
    self.prop_type = :host

    def insync?(is)
      is = [] if is == :absent or is.nil?
      return false unless is.length == should.length
      is.zip(@should).all? {|a, b| property_matches?(a, b) }
    end

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |value|
      fail "IP address:  #{value} is invalid" unless is_host?(value)
    end
  end

  newproperty(:domain) do
    desc "The local domain name"
    class << self
      attr_accessor :prop_type
    end
    self.prop_type = :hostname

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |value|
      is_host?(value,true)
    end
  end

  newproperty(:search, :parent => Puppet::Property::List) do
    desc "The search list for host name lookup.  A maximum of 6 search
              entries may be specified.  Specify multiple search entries as an
              array."

    def should
      @should
    end
    def insync?(is)
      is = [] if is == :absent or is.nil?
      return false unless is.length == should.length
      is.zip(@should).all? {|a, b| property_matches?(a, b) }
    end

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end
    class << self
      attr_accessor :prop_type
    end
    self.prop_type = :hostname

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |value|
      is_host?(value,true)
    end
  end

  newproperty(:sortlist, :parent => Puppet::Property::List) do
    desc "Addresses returned by gethostbyname() to be sorted.  Entries must
              be specified in IP 'slash notation'.  A maximum of 10 sortlist
              entries may be specified.  Specify multiple entries as an array."

    def should
      @should
    end
    def insync?(is)
      is = [] if is == :absent or is.nil?
      return false unless is.length == should.length
      is.zip(@should).all? {|a, b| property_matches?(a, b) }
    end
    class << self
      attr_accessor :prop_type
    end
    self.prop_type = :net_address

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |value|
      is_net_address?(value,true)
    end
  end

  newproperty(:options, :parent => Puppet::Property::List) do
    desc "Set internal resolver variables.  Valid values are debug,
              ndots:n, timeout:n, retrans:n, attempts:n, retry:n, rotate,
              no-check-names, inet6.  For values with 'n', specify 'n' as an
              integer.  Specify multiple options as an array."

    # DNS options
    simple_opts = ["debug", "rotate", "no-check-names", "inet6"]
    arg_opts =  ["ndots", "timeout", "retrans", "attempts", "retry"]

    include PuppetX::Oracle::SolarisProviders::Util::Svcs

    def should_to_s(newvalue)
      to_svcs(newvalue)
    end

    def should
      @should
    end
    def insync?(is)
      is = [] if is == :absent or is.nil?
      return false unless is.length == should.length
      is.sort.zip(@should.sort).all? {|a, b| property_matches?(a, b) }
    end
    class << self
      attr_accessor :prop_type
    end
    self.prop_type = :array

    newvalues('debug','rotate',
              'no-check-names','inet6',
              /ndots:(\d+)?/,/timeout:(\d+)?/,
              /retrans:(\d+)?/,/attempts:(\d+)?/,
              /retry:(\d+)?/,
              :absent)

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end

    validate do |value|
      return true if value == :absent

      data = value.split(":")
      if data.length == 1
        unless simple_opts.include? data[0]
          fail "#{value} is invalid"
        end
      elsif data.length > 2
        fail "#{value} is invalid"
      elsif data.length == 2
        unless arg_opts.include? data[0]
          fail "#{value} is invalid"
        end
        # attempt to cast the integer specified
        begin
          Integer(data[1])
        rescue ArgumentError
          fail "'#{value}' is invalid, can not be cast to an Integer"
        end
      elsif data.empty?
      # Empty values are valid to clear settings in smf
      else
        fail "'#{value}' is invalid"
      end
    end
  end
end
