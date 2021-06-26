#
# Copyright (c) 2013, 2020, Oracle and/or its affiliates.
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

require_relative '../util.rb'
require_relative 'validation.rb'

# Valid svccfg / svcprop arguments
module PuppetX::Oracle::SolarisProviders::Util::Svcs
  # We use valid_... from Validation
  include PuppetX::Oracle::SolarisProviders::Util::Validation

  def svcs_escape(value=self)
    if value.kind_of? String
      value.gsub(/([;|^<>\n\t\\\"\'`~\[\]\$\!])/, '\\\\\1')
    else
      value
    end
  end
  def to_svcs(value=self)
    if value == "absent" || value == :absent
      %q(\'\')
    elsif value.kind_of?(Array)
      value.map{ |val| svcs_escape(val) }
    else
      svcs_escape(value)
    end
  end

  # May want to split this into Provider Functions and Validation
  def munge_value(prop_value,prop_type=nil)
    munged = nil
    wrap = nil

    # This initially started as per-type handling but it doesn't
    # seem that it really needs to be that different
    case prop_type
    when :boolean, :count, :integer, :time, # mostly numbers
         :fmri, :host, :hostname, :net_address, :net_address_v4,
         :net_address_v6, :uri, # more complex strings
         :array # a processing hint for arrays of string type arguments
      wrap = prop_value.kind_of?(Array) ? true : false
      munged = to_svcs(prop_value)
    when :astring, :ustring, :opaque
      # Arrays of string type arguments to be treated as list values
      # must be provided with the hint type :array
      # Debug command output will be somewhat misleading due to \s being eaten
      munged = [prop_value].flatten.map{ |val| to_svcs(val) }.join("\ ")
    else
      # Fall through processing fully escapes the prop_value if we
      # get here without some known type. This will almost certainly be wrong
      # for complex types
      warning "Unknown property type (#{prop_type})" unless prop_type.nil?
      munged = to_svcs(prop_value.to_s)
    end

    if wrap && munged.kind_of?(Array)
      munged.unshift "("
      munged.push ")"
    end
    return munged
  end


  def prop_types
    [
      :boolean, :count, :integer, :time, :fmri, :host, :hostname, :net_address,
      :net_address_v4, :net_address_v6, :uri, :astring, :ustring, :opaque,
      :array # a processing hint for arrays of string type arguments
    ]
  end
  def is_prop_type?(prop_type,fail_on_false=false)
    unless prop_types.include?(prop_type)
      fail "invalid property type" if fail_on_false
      return false
    end
    true
  end
  def pg_types
    [
      :dependency, :framework, :configfile, :method, :template, :application
    ]
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
    unless pg_types.include?(prop_type)
      fail "invalid property group type" if fail_on_false
      return false
    end
    true
  end

  # we assume any non-nil prop_value is valid empty values should be provided
  # as :absent
  def is_astring?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    if prop_value.nil?
      fail "prop_value must be provided use :absent to unset" if fail_on_false
      return false
    end
    true
  end
  alias is_ustring? is_astring?
  alias is_opaque? is_astring?

  def is_boolean?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    unless [:true,:false].include?(prop_value.downcase.to_sym)
      fail "#{prop_value} must be true or false" if fail_on_false
      return false
    end

    true
  end
  def is_count?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    unless prop_value.kind_of?(Integer) || prop_value =~ /\A\d+\Z/
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
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    prop_value.split(/\s+/).each do |v|
      unless v =~ /\A\p{Alpha}+:\/+\p{Graph}+\Z/
        fail "'#{v}' does not appear to be valid" if fail_on_false
        return false
      end
    end

    true
  end
  def is_host?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    prop_value.split(/\s+/).each do |v|
      unless ( valid_hostname?(v) || valid_ip?(v) )
        fail "#{v} invalid valid hostname or ip address" if fail_on_false
        return false
      end
    end

    true
  end
  def is_hostname?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    prop_value.split(/\s+/).each do |v|
      unless valid_hostname?(v)
        fail "#{v} invalid hostname" if fail_on_false
        return false
      end
    end

    true
  end
  def is_integer?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    if prop_value.kind_of?(Numeric)
      unless prop_value.kind_of?(Integer)
        fail "#{prop_value} must be an integer" if fail_on_false
        return false
      end
    else
      unless prop_value =~ /\A-?\d+\Z/
        fail "#{prop_value} must be an integer" if fail_on_false
        return false
      end
    end

    true
  end
  def is_net_address?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    prop_value.split(/\s+/).each do |v|
      unless valid_ip?(v)
        fail "#{v} invalid net_address" if fail_on_false
        return false
      end
    end

    true
  end
  def is_net_address_v4?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    prop_value.split(/\s+/).each do |v|
      unless valid_ipv4?(v)
        fail "#{v} invalid net_address_v4" if fail_on_false
        return false
      end
    end

    true
  end
  def is_net_address_v6?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    prop_value.split(/\s+/).each do |v|
      unless valid_ipv6?(v)
        fail "#{v} invalid net_address_v6" if fail_on_false
        return false
      end
    end

    true
  end
  def is_time?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    unless prop_value.kind_of?(Float) || prop_value.to_f >= 0
      fail "#{prop_value} invalid time" if fail_on_false
      return false
    end

    true
  end
  def is_uri?(prop_value,fail_on_false=false)
    # Check each component if this is an array
    prop_value.each { |val| send(__method__,val)} if prop_value.kind_of? Array
    prop_value.split(/\s+/).each do |v|
      unless v =~ /\A\p{Alpha}+:\p{Graph}+\Z/
        fail "#{v} invalid uri" if fail_on_false
        return false
      end
    end

    true
  end
end
