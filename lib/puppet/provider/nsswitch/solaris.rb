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

Puppet::Type.type(:nsswitch).provide(:nsswitch,
  :parent =>
  Puppet::Type.type(:svccfg).provider(:svccfg)) do
  desc "Provider for name service switch configuration data"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'

  class << self; attr_accessor :nsswitch_fmri end
  Nsswitch_fmri = "svc:/system/name-service/switch"

  mk_resource_methods

  def self.instances
    props = {}
    svcprop("-p", "config", Nsswitch_fmri).each_line.collect do |line|
      fullprop, value = line.split(" ", 3).values_at(0,2)
      prop = fullprop.split("/")[1].intern
      props[prop] = value.strip.delete('\\') \
        if Puppet::Type.type(:nsswitch).validproperties.include? prop
    end

    props[:name] = "current"
    props[:ensure] = :present
    return Array new(props)
  end

  def self.prefetch(resources)
    things = instances
    resources.keys.each { |key|
      things.find { |prop|
        # key.to_s in case name uses newvalues and is converted to symbol
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
    fail "can only be modified not created"
  end
  def destroy
    fail "can only be modified not destroyed"
  end

  Puppet::Type.type(:nsswitch).validproperties.each do |field|
    define_method(field.to_s + "=") do |value|
      begin
        should = munge_value(value,:astring)
        svccfg("-s", Nsswitch_fmri, "setprop", "config/#{field}=#{should}")
        return value
      rescue => detail
        fail "value: #{should.inspect}\n#{detail}\n"
      end
    end
  end

  def flush
    svccfg("-s", Nsswitch_fmri, "refresh")
  end
end
