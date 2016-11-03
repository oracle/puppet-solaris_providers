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


require File.expand_path(File.join(File.dirname(__FILE__), '..','..','puppet_x/oracle/solaris_providers/util/validation.rb'))

Puppet::Type.newtype(:svccfg) do
  @doc = "Manage SMF service properties with svccfg(8)."
  validator = PuppetX::Oracle::SolarisProviders::Util::Validation.new

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
          parameters, or from :name if the format matches"
  end

  newparam(:name) do
    desc <<-HEREDOC
      The symbolic name for properties to manipulate.  When provided as the
      fully composed property FMRI <fmri>/properties:/<property> :fmri,
      :property, and :prop_fmri will be auto-populated.
    HEREDOC

  end

  newparam(:fmri) do
    desc "SMF service FMRI to manipulate"
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
    validation See scf_value_create(3SCF)"

    newvalues(:count, :integer, :opaque, :host, :hostname, :net_address,
              :net_address_v4, :net_address_v6, :time, :astring, :ustring,
              :boolean, :fmri, :uri, :dependency, :framework, :configfile,
              :method, :template, :template_pg_pattern,
              :template_prop_pattern)

  end

  newproperty(:value) do
    desc "Value of the property. Value types :fmri, :opaque, :host, :hostname,
      :net_address, :net_address_v4, :net_address_v6, and :uri are treated as
      lists if they contain whitespace. See scf_value_create(3SCF)"

      # escape bourne shell characters in the should value
      def insync?(is)
          is.to_s == should.to_s.gsub(/([;&()|^<>\n \t\\\"\'`~*\[\]\$\!])/,
                                      '\\\\\1')

      end
  end


  validate {
    # Validation must happen after we have both the type and value.

    # Don't run top level validation unless there is an ensure property
    unless self[:ensure].nil?
      if self[:prop_fmri] && ( self[:fmri].nil? || self[:property].nil? )
        a = self[:prop_fmri].split(%r(/:properties/),2)
        self[:fmri] ||= a[0]
        self[:property] ||= a[1]
      end

      fail ":fmri is required" unless self[:fmri]
      fail ":property is required" unless self[:property]

      # Don't check for presence of value for property group types
      unless [:dependency, :framework, :configfile, :method, :template,
        :template_pg_pattern, :template_prop_pattern].include?(self[:type])
        # self.provider.value is set in prefetch
        fail ":value is required" if self[:value].nil? && self.provider.value.nil?
      end

    end

    self[:prop_fmri] ||= "#{self[:fmri]}/:properties/#{self[:property]}"


    #
    # Validate Value arguments based on type
    #
    # :astring, :ustring, :boolean, :count, :integer, :time are evaluated
    # as is. Other types are split on whitespace with each component
    # checked for validity.
    case self[:type]
    when :astring, :ustring, :opaque

    when :boolean
      unless [:true,:false].include?(self[:value].downcase.to_sym)
        fail "#{self[:type]} must be true or false"
      end

    when :count
      unless self[:value].kind_of?(Integer) || self[:value].match(/\A\d+\Z/)
        fail "#{self[:type]}:#{self[:value]} must be an integer"
      end
      unless self[:value].to_i >= 0
        fail "#{self[:type]}:#{self[:value]} must be unsigned"
      end

    when :fmri
      self[:value].split(/\s+/).each { |v|
        unless v.match(/\A\p{Alpha}+:\/+\p{Graph}+\Z/)
          fail "#{self[:type]}:'#{v}' does not appear to be valid"
        end
      }

    when :host
      self[:value].split(/\s+/).each { |v|
        unless ( validator.valid_hostname?(v) || validator.valid_ip?(v) )
          fail "#{self[:type]}:#{v} is not a valid hostname or ip address"
        end
      }

    when :hostname
      self[:value].split(/\s+/).each { |v|
        unless validator.valid_hostname?(v)
          fail "#{self[:type]}:#{v} is not valid"
        end
      }

    when :integer
      if self[:value].kind_of?(Numeric)
        unless self[:value].kind_of?(Integer)
          fail "#{self[:type]} must be an integer"
        end
      else
        unless self[:value].match(/\A-?\d+\Z/)
          fail "#{self[:type]} must be an integer"
        end
      end

    when :net_address
      self[:value].split(/\s+/).each { |v|
        unless validator.valid_ip?(v)
          fail "#{self[:type]}:#{v} is not valid"
        end
      }

    when :net_address_v4
      self[:value].split(/\s+/).each { |v|
        unless validator.valid_ipv4?(v)
          fail "#{self[:type]}:#{v} is not valid"
        end
      }

    when :net_address_v6
      self[:value].split(/\s+/).each { |v|
        unless validator.valid_ipv6?(v)
          fail "#{self[:type]}:#{v} is not valid"
        end
      }

    when :time
      unless  self[:value].kind_of?(Float) || self[:value].to_f >= 0
        fail "#{self[:type]}:#{self[:value]} is not valid"
      end

    when :uri
      self[:value].split(/\s+/).each { |v|
        unless v.match(/\A\p{Alpha}+:\p{Graph}+\Z/)
          fail "#{self[:type]}:#{v} is not valid"
        end
      }

    when :dependency, :framework, :configfile, :method, :template,
      :template_pg_pattern, :template_prop_pattern
      fail "#{self[:type]} implies a property group. Property group names cannot contain /" if (
        self[:property].match('/')
      )

      fail "Property groups do not take values" unless self[:value].nil?
    end

  }
end
