#
# Copyright (c) 2013, 2106, Oracle and/or its affiliates. All rights reserved.
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

require 'shellwords'
require File.expand_path(File.join(File.dirname(__FILE__), '..','util.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'validation.rb'))



# Valid svccfg / svcprop arguments
module PuppetX::Oracle::SolarisProviders::Util::Svcs

  module ToSvcs
    def svcs_escape(value=self)
      if value.kind_of? String
        value.gsub(/([;&()|^<>\n \t\\\"\'`~*\[\]\$\!])/, '\\\\\1')
      else
        value
      end
    end
    def to_svcs
      if self == :absent
        %q(\'\')
      elsif self.kind_of?(Array)
        self.map{ |val| svcs_escape(val) }.join(" ")
      else
        self.svcs_escape
      end
    end
  end

  # We use valid_... from Validation
  include PuppetX::Oracle::SolarisProviders::Util::Validation

  # May want to split this into Provider Functions and Validation
  def munge_value(prop_value,prop_type=nil)
    munged = nil

    # Add our ToSvcs methods to prop_value
    prop_value.extend PuppetX::Oracle::SolarisProviders::Util::Svcs::ToSvcs
    # This initially started as per-type handling but it doesn't
    # seem that it really needs to be that different
    case prop_type
    when :boolean, :count, :integer, :time, # mostly numbers
         :astring, :ustring, :opaque, # mostly strings
         :fmri, :host, :hostname, :net_address, :net_address_v4,
           :net_address_v6, :uri # more complex strings
        munged = prop_value.to_svcs
    else
      # Fall through processing fully escapes the prop_value if we
      # get here without some known type
      warn ("Unknown property type (#{prop_type})")
      munged = prop_value.svcs_escape
    end

    # Wrap the resulting string in ()s and return it
    return "(#{munged})"
  end



  # The provided prop_value is a valid property group type
  def is_pg_valid?(prop_value,fail_on_false=false)
    unless prop_value.nil?
      fail "Property groups do not take values" if fail_on_false
      return false
    end
    true
  end
  def is_pg_type?(prop_type,fail_on_false=false)
    unless [:dependency, :framework, :configfile, :method, :template,
        :template_pg_pattern, :template_prop_pattern].include?(prop_type)
      fail "invalid property group type" if fail_on_false
      return false
    end
    true
  end
  def is_pg_wellformed?(property,fail_on_false=false)
    if property.match('/')
      fail "Property group names cannot contain /" if fail_on_false
      return false
    end
    true
  end

  # we assume any non-nil prop_value is valid empty values should be provided
  # as :absent
  def is_astring?(prop_value,fail_on_false=false)
    if prop_value.nil?
      fail "prop_value must be provided use :absent to unset" if fail_on_false
      return false
    end
    true
  end
  alias is_ustring? is_astring?
  alias is_opaque? is_astring?


  def is_boolean?(prop_value,fail_on_false=false)
    unless [:true,:false].include?(prop_value.downcase.to_sym)
      fail "#{prop_value} must be true or false" if fail_on_false
      return false
    end

    true
  end
  def is_count?(prop_value,fail_on_false=false)
    unless prop_value.kind_of?(Integer) || prop_value.match(/\A\d+\Z/)
      fail "#{prop_value} must be an integer" if fail_on_false
      return false
    end
    unless prop_value.to_i >= 0
      fail "#{prop_value} must be unsigned" if fail_on_false
      return false
    end

    true
  end
  def is_fmri?(prop_value,fail_on_false=false)
    prop_value.split(/\s+/).each { |v|
      unless v.match(/\A\p{Alpha}+:\/+\p{Graph}+\Z/)
        fail "'#{v}' does not appear to be valid" if fail_on_false
        return false
      end
    }

    true
  end
  def is_host?(prop_value,fail_on_false=false)
    prop_value.split(/\s+/).each { |v|
      unless ( valid_hostname?(v) || valid_ip?(v) )
        fail "#{v} invalid valid hostname or ip address" if fail_on_false
        return false
      end
    }

    true
  end
  def is_hostname?(prop_value,fail_on_false=false)
    prop_value.split(/\s+/).each { |v|
      unless valid_hostname?(v)
        fail "#{v} invalid hostname" if fail_on_false
        return false
      end
    }

    true
  end
  def is_integer?(prop_value,fail_on_false=false)
    if prop_value.kind_of?(Numeric)
      unless prop_value.kind_of?(Integer)
        fail "#{v} must be an integer" if fail_on_false
        return false
      end
    else
      unless prop_value.match(/\A-?\d+\Z/)
        fail "#{v} must be an integer" if fail_on_false
        return false
      end
    end

    true
  end
  def is_net_address?(prop_value,fail_on_false=false)
    prop_value.split(/\s+/).each { |v|
      unless valid_ip?(v)
        fail "#{v} invalid net_address" if fail_on_false
        return false
      end
    }

    true
  end
  def is_net_address_v4?(prop_value,fail_on_false=false)
    prop_value.split(/\s+/).each { |v|
      unless valid_ipv4?(v)
        fail "#{v} invalid net_address_v4" if fail_on_false
        return false
      end
    }

    true
  end
  def is_net_address_v6?(prop_value,fail_on_false=false)
    prop_value.split(/\s+/).each { |v|
      unless valid_ipv6?(v)
        fail "#{v} invalid net_address_v6" if fail_on_false
        return false
      end
    }

    true
  end
  def is_time?(prop_value,fail_on_false=false)
    unless  prop_value.kind_of?(Float) || prop_value.to_f >= 0
      fail "#{prop_value} invalid time" if fail_on_false
      return false
    end

    true
  end
  def is_uri?(prop_value,fail_on_false=false)
    prop_value.split(/\s+/).each { |v|
      unless v.match(/\A\p{Alpha}+:\p{Graph}+\Z/)
        fail "#{v} invalid uri" if fail_on_false
        return false
      end
    }

    true
  end
end

