#
# Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:evs).provide(:solaris) do
  desc "Provider for managing EVS setup in the Solaris OS"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ["5.11", "5.12"]
  commands :evsadm => "/usr/sbin/evsadm"

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.get_evs_list
    begin
      evs_list = evsadm("show-evs", "-c", "-o", "evs,tenant,status")
                   .split("\n")
    rescue Puppet::ExecutionFailure => e
      fail "Unable to populate EVS instances: \n" \
                           "#{e.inspect}"
    end
    evs_list
  end

  def self.get_evs_properties(evs, tenant, status, ensure_val)
    evs_properties = {}
    evs_fullname = tenant + "/" + evs

    evs_properties[:name] = evs_fullname
    evs_properties[:status] = status
    evs_properties[:ensure] = ensure_val

    evsadm("show-evsprop", "-f", "tenant=#{tenant}", "-c", "-o",
           "property,value", evs).split("\n").collect do |each_evsprop|
      property, value = each_evsprop.split(":")
      value = "" if value.nil?
      case property
      # read/write properties (always updatable)
      when "maxbw"
        evs_properties[:maxbw] = value
      when "priority"
        evs_properties[:priority] = value
      when "protection"
        evs_properties[:protection] = value
      # read-only properties (settable upon creation)
      when "l2-type"
        evs_properties[:l2_type] = value
      when "vlanid"
        evs_properties[:vlanid] = value
      when "vni"
        evs_properties[:vni] = value
      when "uuid"
        evs_properties[:uuid] = value
      end
    end

    Puppet.debug "EVS Properties: #{evs_properties.inspect}"
    evs_properties
  end

  def self.instances
    get_evs_list.collect do |each_evs|
      evs, tenant, status = each_evs.strip.split(":")
      evs_properties = get_evs_properties(evs, tenant, status, :present)
      new(evs_properties) # Create a provider instance
    end
  end

  def self.prefetch(resources)
    instances.each do |inst|
      if resource = resources[inst.name]
        resource.provider = inst
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    tenant, evs = get_tenant_and_evs_name
    begin
      create_evs(tenant, evs, add_properties(@resource))
    rescue Puppet::ExecutionFailure => e
      fail "Cannot create EVS: \n#{e.inspect}"
    end
  end

  def destroy
    tenant, evs = get_tenant_and_evs_name
    begin
      delete_evs(tenant, evs)
    rescue Puppet::ExecutionFailure => e
      fail "Cannot delete EVS: \n#{e.inspect}"
    end
  end

  ### Define Setters ###
  ## read/write properties (always updatable) ##
  def maxbw=(value)
    @property_flush[:maxbw] = value
  end

  def priority=(value)
    @property_flush[:priority] = value
  end

  def protection=(value)
    @property_flush[:protection] = value
  end

  ## read-only properties (settable upon creation) ##
  def l2_type=(value)
    fail "l2_type property is settable only upon creation"
  end

  def vlanid=(value)
    fail "valid property is settable only upon creation"
  end

  def vni=(value)
    fail "vni property is settable only upon creation"
  end

  def uuid=(value)
    fail "uuid property is settable only upon creation"
  end

  # Create EVS instance
  def create_evs(tenant, evs, properties)
    begin
      evsadm("create-evs", "-T", tenant, properties, evs)
    rescue Puppet::ExecutionFailure => e
      # Pass up the exception to upper level
      raise
    end
  end

  # Destroy EVS instance
  def delete_evs(tenant, evs)
    begin
      evsadm("delete-evs", "-T", tenant, evs)
    rescue Puppet::ExecutionFailure => e
      # Pass up the exception to upper level
      raise
    end
  end

  # Set read/write property of EVS instance
  def set_evsprop(tenant, evs, property)
    begin
      evsadm("set-evsprop", "-T", tenant, property, evs)
    rescue Puppet::ExecutionFailure => e
      # Pass up the exception to upper level
      raise
    end
  end

  # Parse the "name" value from user and yield tenant and EVS instance name
  def get_tenant_and_evs_name()
    usrstr = @resource[:name].split("/")
    if usrstr.length == 2
      return usrstr[0], usrstr[1]
    else
      fail "Invalid EVS name #{@resource[:name]} \n" \
                           "Name convention must be <tenant>/<evs>"
    end
  end

  # property setter for EVS creation
  def add_properties(source)
    p = []
    prop_list = {
      "maxbw" => source[:maxbw],
      "priority" => source[:priority],
      "protection" => source[:protection],
      "l2-type" => source[:l2_type],
      "vlanid" => source[:vlanid],
      "vni" => source[:vni],
      "uuid" => source[:uuid]
    }
    prop_list.each do |key, value|
      next if (value == nil) || (value == "")
      p << "#{key}=#{value}"
    end
    return [] if p.empty?
    properties = Array["-p", p.join(",")]
  end

  # Update property change
  def flush
    tenant, evs = get_tenant_and_evs_name

    # Update property values when specified
    unless @property_flush.empty?
      # update multiple property values iteratively
      @property_flush.each do |key, value|
        prop = ["-p", "#{key}=#{value}"]
        begin
          set_evsprop(tenant, evs, prop)
        rescue Puppet::ExecutionFailure => e
          fail "Cannot update the property " \
                               "#{key}=#{value}.\n#{e.inspect}"
        end
      end
    end
    # Synchronize all the SHOULD values to IS values
    @property_hash = resource.to_hash
  end
end
