#
#   Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
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

# This is only a pre-configured instance of svccfg
Puppet::Type.type(:nis).provide(:nis,
                                :parent =>
                                Puppet::Type.type(:svccfg).provider(:svccfg)) do

  desc "Provider for management of NIS client for Oracle Solaris"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

  class << self; attr_accessor :client_fmri, :domain_fmri end
  Client_fmri = "svc:/network/nis/client".freeze
  Domain_fmri = "svc:/network/nis/domain".freeze


  mk_resource_methods

  def self.instances
    props = {}
    validprops = Puppet::Type.type(:nis).validproperties

    [Client_fmri, Domain_fmri].each do |svc|
      svcprop("-p", "config", svc).each_line do |line|
        data = line.split()
        fullprop = data[0]
        value =
          if data.length > 2
            data[2..-1].join(" ")
          end

        prop = fullprop.split("/")[1].intern
        # Rebuild securenets input format
        if prop == :securenets
          ary = value.delete('\\').split
          value = []
          ary.each_with_index do |val,idx|
            val = '' if val == 'host'
            if idx.even?
              value.push(val)
            else
              value[-1] << '/' unless value[-1] && value[-1].empty?
              value[-1] << val
            end
          end
        end
        props[prop] = value if validprops.include? prop.to_sym
      end
    end
    props[:name] = "current"
    props[:ensure] = :present
    return Array new(props)
  end

  def self.prefetch(resources)
    things = instances
    resources.keys.each do |key|
      things.find do |prop|
        # key.to_s in case name uses newvalues and is converted to symbol
        prop.name == key.to_s
      end.tap do |provider|
        next if provider.nil?
        resources[key].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    fail "Cannot create a new instance. Use the fixed name 'current'"
  end

  # svc:/network/nis/client properties
  [:use_broadcast, :use_ypsetme].each do |field|
    # Don't define accessors, mk_resource_methods and instances pre-populate
    define_method(field.to_s + "=") do |should|
      begin
        value = munge_value(should,:boolean)
        svccfg("-s", Client_fmri, "setprop", "config/#{field}=", value)
        return should
      rescue => detail
        fail "value: #{should.inspect}\n#{detail}\n"
      end
    end
  end

  def securenets=(should)
    begin
      field = :securenets
      prop_type = Puppet::Type::Nis.propertybyname(field).prop_type
      value = munge_value(should,prop_type)
      svccfg("-s", Domain_fmri, "setprop", "config/#{field}=", value)
      return should == :absent ? should : value
    rescue => detail
      fail "value: #{should.inspect}\n#{detail}\n"
    end
  end

  # svc:/network/nis/domain properties
  [:domainname, :ypservers].each do |field|
    prop_type = Puppet::Type::Nis.propertybyname(field).prop_type
    # Don't define accessors, mk_resource_methods and instances pre-populate

    define_method(field.to_s + "=") do |should|
      begin
        value = munge_value(should,prop_type)
        svccfg("-s", Domain_fmri, "setprop", "config/#{field}=", value)
        return should == :absent ? should : value
      rescue => detail
        fail "value: #{should.inspect}\n#{detail}\n"
      end
    end
  end

  def flush
    svccfg("-s", Domain_fmri, "refresh")
    svccfg("-s", Client_fmri, "refresh")
  end
end
