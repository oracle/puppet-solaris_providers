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


Puppet::Type.type(:evs_vport).provide(:evs_vport) do
  desc "Provider for managing EVS VPort setup in the Solaris OS"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ["5.11", "5.12"]
  commands :evsadm => "/usr/sbin/evsadm"

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.get_vport_list
    begin
      vport_list = evsadm("show-vport", "-c", "-o",
                          "name,tenant,status").split("\n")
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "unable to populate VPort instances: \n" \
                           "#{e.inspect}"
    end
    vport_list
  end

  def self.get_vport_properties(vport, tenant, status, ensure_val)
    vport_props = {}
    vport_fullname = tenant + "/" + vport
    vport_props[:name] = vport_fullname
    vport_props[:status] = status
    vport_props[:ensure] = ensure_val

    evsadm("show-vportprop", "-f", "tenant=#{tenant}", "-c", "-o",
           "property,value", vport).split("\n").collect do |each_prop|
      property, value = each_prop.split(":", 2)
      value = "" if value.nil?
      case property
      # read/write properties (always updatable)
      when "cos"
        vport_props[:cos] = value
      when "maxbw"
        vport_props[:maxbw] = value
      when "priority"
        vport_props[:priority] = value
      when "protection"
        vport_props[:protection] = value
      # read-only properties (settable upon creation)
      when "ipaddr"
        vport_props[:ipaddr] = value
      when "macaddr"
        # macaddr ":" appears to be "\:". change it to ":"
        vport_props[:macaddr] = value.gsub! "\\:", ":"
      when "uuid"
        vport_props[:uuid] = value
      end
    end

    Puppet.debug "VPort properties: #{vport_props.inspect}"
    vport_props
  end

  def self.instances
    get_vport_list.collect do |each_vport|
      vport, tenant, status = each_vport.strip.split(":")
      vport_props = get_vport_properties(vport, tenant, status, :present)
      new(vport_props) # Create a provider instance
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
    tenant, vport = get_tenant_and_vport_name
    begin
      create_vport(tenant, vport, add_properties(@resource))
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Cannot add VPort: \n #{e.inspect}"
    end
  end

  def destroy
    tenant, vport = get_tenant_and_vport_name
    begin
      delete_vport(tenant, vport)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Cannot remove VPort: \n #{e.inspect}"
    end
  end

  def reset
    tenant, vport = get_tenant_and_vport_name
    begin
      evsadm("reset-vport", "-T", tenant, vport)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Cannot reset VPort: \n #{e.inspect}"
    end

    @resource[:ensure] = :present
    Puppet::notice "The VPort has been successfully reset."
  end

  ### Define Setters ###
  ## read/write properties (always updatable) ##
  def cos=(value)
    @property_flush[:cos] = value
  end

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
  def ipaddr=(value)
    raise Puppet::Error, "ipaddr property is settable only upon creation"
  end

  def macaddr=(value)
    raise Puppet::Error, "macaddr property is settable only upon creation"
  end

  def uuid=(value)
    raise Puppet::Error, "uuid property is settable only upon creation"
  end

  # Add VPort Instance
  def create_vport(tenant, vport, properties)
    begin
      evsadm("add-vport", "-T", tenant, properties, vport)
    rescue Puppet::ExecutionFailure => e
      # Pass up the exception to upper level
      raise e
    end
  end

  # Remove Vport Instance
  def delete_vport(tenant, vport)
    begin
      evsadm("remove-vport", "-T", tenant, vport)
    rescue Puppet::ExecutionFailure
      # Pass up the exception to upper level
      raise
    end
  end

  # set read/write property
  def set_vportprop(tenant, vport, property)
    begin
      evsadm("set-vportprop", "-T", tenant, property, vport)
    rescue Puppet::ExecutionFailure
      # Pass up the exception to upper level
      raise
    end
  end

  # Parse the "name" value from user and yield tenant and vport name
  def get_tenant_and_vport_name
    fullname = @resource[:name]

    return [] if fullname == nil
    parsed_val = fullname.strip.split("/")
    if (parsed_val.length != 3)
      raise Puppet::Error, "Invalid VPort name #{@resource[:name]} \n" \
                           "Name convention must be <tenant>/<evs>/<vport>"
    end
    tenant, evs, vport = parsed_val
    return tenant, evs + "/" + vport
  end

  # property setter for vport creation
  def add_properties(source)
    p = []
    if source[:ipaddr] != nil
      source[:ipaddr] = source[:ipaddr].split('/')[0]
    end
    prop_list = {
      "cos" => source[:cos],
      "maxbw" => source[:maxbw],
      "priority" => source[:priority],
      "protection" => source[:protection],
      "ipaddr" => source[:ipaddr],
      "macaddr" => source[:macaddr],
      "uuid" => source[:uuid]
    }
    prop_list.each do |key, value|
      next if (value == "") || (value == nil)
      p << "#{key}=#{value}"
    end
    return [] if p.empty?
    Array["-p", p.join(",")]
  end

  # Update property change
  def flush
    tenant, vport = get_tenant_and_vport_name

    # Update property values when specified
    unless @property_flush.empty?
      # update multiple property values iteratively
      @property_flush.each do |key, value|
        prop = ["-p", "#{key}=#{value}"]
        begin
          set_vportprop(tenant, vport, prop)
        rescue Puppet::ExecutionFailure => e
          raise Puppet::Error, "Cannot update the property " \
                               "#{key}=#{value}.\n#{e.inspect}"
        end
      end
    end

    # Synchronize all the SHOULD values to IS values
    @property_hash = resource.to_hash
  end
end
