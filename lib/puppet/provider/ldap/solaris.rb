#
# Copyright (c) 2013, 2014, Oracle and/or its affiliates. All rights reserved.
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
Puppet::Type.type(:ldap).provide(:ldap,
                                 :parent =>
Puppet::Type.type(:svccfg).provider(:svccfg)) do

  desc "Provider for management of the LDAP client for Oracle Solaris"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

  Ldap_fmri = "svc:/network/ldap/client"


  mk_resource_methods

  def self.instances
    if Process.euid != 0
      # Failure is presumed to be better than returning the empty
      # set. We expect Puppet needs to always run as root so this
      # may be moot outside of testing
      fail "LDAP configuration is not availble to non-root users"
    end
    props = {}
    validprops = Puppet::Type.type(:ldap).validproperties
    svcprop("-p", "config", "-p", "cred", Ldap_fmri).split("\n").collect do |line|
      data = line.split()
      fullprop = data[0]
      _type = data[1]
      if data.length > 2
        value = data[2..-1].join(" ")
      else
        value = nil
      end

      _pg, prop = fullprop.split("/")
      prop = prop.intern

      props[prop] = value if validprops.include? prop
    end

    props[:name] = "current"
    props[:ensure] = :present
    return Array new(props)
  end

  def self.prefetch(resources)
    things = instances
    resources.keys.each { |key|
      things.find { |prop|
        # key is unexpectedly coming from resource as a symbol
        prop.name == key.to_s
      }.tap { |provider|
        next if provider.nil?
        resources[key].provider = provider
      }
    }
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    fail "Cannot create a new instance. Use the fixed name 'current'"
  end

  # Define getters and setters
  Puppet::Type.type(:ldap).validproperties.each do |field|
    next if [:ensure].include?(field)
    # get the property group
    pg = Puppet::Type::Ldap.propertybyname(field).pg
    prop_type = Puppet::Type::Ldap.propertybyname(field).prop_type

    # Don't define accessors, mk_resource_methods and instances pre-populate

    define_method(field.to_s + "=") do |should|
      begin
        value = munge_value(should, prop_type)
        svccfg("-s", Ldap_fmri, "setprop", "#{pg}/#{field}=", value)
        return value
      rescue => detail
        fail "value: #{should.inspect}\n#{detail}\n"
      end
    end
  end

  def flush
    svccfg("-s", Ldap_fmri, "refresh")
  end
end
