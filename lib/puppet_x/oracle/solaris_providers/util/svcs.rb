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

  # We use valid_... from Validation
  include PuppetX::Oracle::SolarisProviders::Util::Validation

  # May want to split this into Provider Functions and Validation
  def munge_value(prop_value,prop_type=nil)
    munged = nil

    # Return the empty string if prop_value is :absent
    if prop_value == :absent
      return %q(\'\')
    end

    # reformat values which may be lists.
    # :array is not a valid type but it provides a processing hint
    case prop_type
    when :boolean, :count, :integer, :time
      if prop_value.kind_of?(Array)
        munged = "\\(#{prop_value.svcs_escape}\\)"
      end
    when :astring, :ustring, :opaque
      if prop_value.kind_of?(Array)
        munged = "\\(#{prop_value.map(&:shellescape).join(" ")}\\)"
      end
    when :fmri, :host, :hostname, :net_address, :net_address_v4,
      :net_address_v6, :uri, :array
      if prop_value.kind_of?(Array)
        munged = "\\(#{prop_value.shelljoin}\\)"
      elsif prop_value.split.length > 1
        munged = "\\(#{prop_value.split.shelljoin}\\)"
      end
    end

    # Fall through processing fully escapes the prop_value if munged
    # isn't defined. Includes special characters and spaces
    munged ||= prop_value.svcs_escape

    return munged
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
