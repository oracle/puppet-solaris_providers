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


Puppet::Type.type(:evs_ipnet).provide(:solaris) do
  desc "Provider for managing EVS IPnet setup in the Solaris OS"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ["5.11"]
  commands :evsadm => "/usr/sbin/evsadm"

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.get_ipnet_prop_list
    begin
      ipnet_list = evsadm("show-ipnet", "-c", "-o",
                          "name,tenant").split("\n")
    rescue Puppet::ExecutionFailure => e
      fail "Unable to populate IPnet: \n#{e.inspect}"
    end
    ipnet_list
  end

  def self.get_ipnet_properties(ipnet_name, tenant, ensure_val)
    ipnet_properties = {}
    ipnet_fullname = tenant + "/" + ipnet_name

    ipnet_properties[:name] = ipnet_fullname
    ipnet_properties[:ensure] = ensure_val

    evsadm("show-ipnetprop", "-f", "tenant=#{tenant}", "-c", "-o",
           "property,value", ipnet_name).split("\n").collect do |each_ipnet|
      property, value = each_ipnet.split(":")
      value = "" if value.nil?
      case property
      # read-only properties (settable upon creation)
      when "subnet"
        ipnet_properties[:subnet] = value
      when "defrouter"
        ipnet_properties[:defrouter] = value
      when "uuid"
        ipnet_properties[:uuid] = value
      # read/write property (always updatable)
      when "pool"
        ipnet_properties[:pool] = value
      end
    end

    Puppet.debug "IPnet Properties: #{ipnet_properties.inspect}"
    ipnet_properties
  end

  def self.instances
    get_ipnet_prop_list.collect do |each_ipnet|
      ipnet, tenant, subnet = each_ipnet.strip.split(":")
      ipnet_properties = get_ipnet_properties(
        ipnet, tenant, :present
      )
      new(ipnet_properties) # Create a provider instance
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
    # Subnet value is required to create an IPnet instance
    if @resource[:subnet].nil?
      fail "Subnet value is missing"
    end

    tenant, ipnet_name = get_tenant_and_ipnet_name
    begin
      create_ipnet(tenant, ipnet_name, add_properties(@resource))
    rescue Puppet::ExecutionFailure => e
      fail "Cannot add the IPnet: \n #{e.inspect}"
    end
  end

  def destroy
    tenant, ipnet_name = get_tenant_and_ipnet_name
    begin
      delete_ipnet(tenant, ipnet_name)
    rescue Puppet::ExecutionFailure => e
      fail "Cannot remove the IPnet: \n #{e.inspect}"
    end
  end

  ## read-only properties (settable upon creation) ##
  def defrouter=(value)
    fail "defrouter property is settable only upon creation"
  end

  def subnet=(value)
    fail "subnet property is settable only upon creation"
  end

  def uuid=(value)
    fail "uuid property is settable only upon creation"
  end

  ## read/write property (always updatable) ##
  def pool=(value)
    @property_flush[:pool] = value
  end

  ## Create IPnet instance ##
  def create_ipnet(tenant, ipnet_name, properties)
    begin
      evsadm("add-ipnet", "-T", tenant, properties, ipnet_name)
    rescue Puppet::ExecutionFailure => e
      # Pass up the exception to upper level
      raise
    end
  end

  ## Remove IPnet instance ##
  def delete_ipnet(tenant, ipnet_name)
    begin
      evsadm("remove-ipnet", "-T", tenant, ipnet_name)
    rescue Puppet::ExecutionFailure => e
      # Pass up the exception to upper level
      raise
    end
  end

  ## Set IPnet prop (pool property only) ##
  def set_ipnet(tenant, ipnet_name, property)
    begin
      evsadm("set-ipnetprop", "-T", tenant, property, ipnet_name)
    rescue Puppet::ExecutionFailure => e
      # Pass up the exception to upper level
      raise
    end
  end

  ## Parse the "name" value from user and yield tenant and IPnet name ##
  def get_tenant_and_ipnet_name
    fullname = @resource[:name]

    parsed_val = fullname.strip.split("/")
    if (parsed_val.length != 3)
      fail "Invalid IPnet name"
    end
    tenant, evs, ipnet = parsed_val
    return tenant, evs + "/" + ipnet
  end

  ## property setter for IPnet creation ##
  def add_properties(source)
    p = []
    prop_list = {
      "defrouter" => source[:defrouter],
      "pool" => source[:pool],
      "subnet" => source[:subnet],
      "uuid" => source[:uuid]
    }
    prop_list.each do |key, value|
      next if (value == nil) || (value == "")
      p << "#{key}=#{value}"
    end
    return [] if p.empty?
    properties = Array["-p", p.join(",")]
  end

  ## Flush when existing property value is updatable ##
  def flush
    tenant, ipnet_name = get_tenant_and_ipnet_name

    unless @property_flush.empty?
      # Update read/write property (pool)
      pool_prop = ["-p", "pool=#{@property_flush[:pool]}"]
      begin
        set_ipnet(tenant, ipnet_name, pool_prop)
      rescue Puppet::ExecutionFailure => e
        fail "Cannot update the pool property. \n" \
                             "#{e.inspect}"
      end
    end

    # Synchronize all the SHOULD values to IS values
    @property_hash = resource.to_hash
  end
end
