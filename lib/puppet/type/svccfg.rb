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

Puppet::Type.newtype(:svccfg) do
  @doc = "Manage SMF service properties with svccfg(8)."
  include PuppetX::Oracle::SolarisProviders::Util::Svcs

  ensurable do
    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    newvalue(:delcust) do
      provider.delcust
    end
  end

  # name/title in the format fully defined fmri will be parsed to automatically
  # populate parameters
  def self.title_patterns
    [
      [ %r^(((.*)/:properties/(.*)))^, [ [:name],[:prop_fmri],[:fmri],[:property] ] ],
      [ /(.*)/m, [ [:name] ] ]
    ]

  end

  # This is a parameter, it cannot be changed. It must be defined this way to be
  # displayed in puppet resource svccfg output
  newproperty(:prop_fmri, :namevar => true) do
    desc "The fully composed property FMRI <fmri>/properties:/<property>
          if left blank it will be built from the :fmri and :property
          parameters, or from :name if the format matches.
          FMRI must be fully qualified as svc:/path"

    newvalues(%r(^svc:/))

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |value|
      is_fmri?(value,true)
    end
  end

  newparam(:name) do
    desc "The symbolic name for properties to manipulate.  When provided as the
    fully composed property FMRI <fmri>/properties:/<property> :fmri,
    :property, and :prop_fmri will be auto-populated."

  end

  newparam(:fmri) do
    desc "SMF service FMRI to manipulate.
    FMRI must be fully qualified as svc:/path"

    newvalues(%r(^svc:/))

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |value|
      is_fmri?(value,true)
    end
  end

  newparam(:property) do
    desc "Name of property - includes Property Group and Property.  If
              the service, instance, or property group does not exist, they
              will be created."
  end

  # Type is a parameter, it cannot be changed. It must be defined this way to be
  # displayed in puppet resource svccfg output
  newproperty(:type) do
    desc "Type of the property. Type must be defined for server side :value
    validation See scf_value_create(3SCF).

    String type arguments passed as an array will be treated as a single string.
    For multi-value string lists use type => array (RARE)"

    newvalues(:count, :integer, :opaque, :host, :hostname, :net_address,
              :net_address_v4, :net_address_v6, :time, :astring, :ustring,
              :boolean, :fmri, :uri, :dependency, :framework, :configfile,
              :method, :template, :template_pg_pattern,
              :template_prop_pattern)

  end

  newproperty(:value, :array_matching => :all) do
    desc "Value of the property. Value types :fmri, :opaque, :host, :hostname,
      :net_address, :net_address_v4, :net_address_v6, and :uri are treated as

      lists if they contain whitespace. Most array arguments are also treated
      as lists. See scf_value_create(3SCF)"

    include PuppetX::Oracle::SolarisProviders::Util::Svcs

    def should_to_s(newvalue)
      to_svcs(newvalue)
    end

    def should
      if @should.size == 1
        @should = @should[0]
      end
      return @should
    end

    def insync?(is)
      if is.kind_of? NilClass || is == :absent
        is = ""
      end
      if is.respond_to?(:zip)
        is.zip(@should).all? {|a, b| property_matches?(a, b) }
      else
        is == should_to_s(munge_value(should,resource[:type]))
      end
    end
  end

  validate {
    # Validation must happen after we have both the type and value.

    # Skip validation if we are in instances/prefetch
    if (self[:type].nil? && self[:value].nil?) &&
       self.provider &&
       (!self.provider.type.nil? && !self.provider.value.nil?)
      next
    end

    # Don't run top level validation unless there is an ensure property
    # Munge prop_fmri into fmri and property if they are not set
    unless self[:ensure].nil?
      if self[:prop_fmri] && ( self[:fmri].nil? || self[:property].nil? )
        a = self[:prop_fmri].split(%r(/:properties/),2)
        self[:fmri] ||= a[0]
        self[:property] ||= a[1]
      end

      fail ":fmri is required" unless self[:fmri]
      fail ":property is required" unless self[:property]

      # Skip value validation for absent and delcust
      if self[:ensure] != :present
        return true
      end

      # Value is required for non-property groups and
      # invalid for property groups
      unless is_pg_type?(self[:type])

        if self[:value].nil? && (self.provider && self.provider.value.nil?)
          fail ":value is required for setting properties"
        end
      else
        is_pg_valid?(self[:value],true)
      end
    end

    self[:prop_fmri] ||= "#{self[:fmri]}/:properties/#{self[:property]}"


    # Treat value as an array in any configuration
    [self[:value]].flatten.each { |val|
      #
      # Validate Value arguments based on type
      case self[:type]
      when :astring, :ustring, :opaque, :boolean, :count, :fmri, :host, :hostname,
           :integer, :net_address, :net_address_v4, :net_address_v6, :time, :uri
        self.send(:"is_#{self[:type]}?", val,true)
      when :dependency, :framework, :configfile, :method, :template,
           :template_pg_pattern, :template_prop_pattern
      # These are property groups
      when nil, :absent
        warning "Type should be provided in resource definition"
      else
        fail "unknown type #{self[:type]}"
      end
    }
  }

  # Auto require property groups if they exist
  autorequire(:svccfg) do
    [self[:prop_fmri].slice(0,self[:prop_fmri].rindex('/'))]
  end
end
