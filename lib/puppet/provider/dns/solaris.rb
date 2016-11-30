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
#
# This is only a pre-configured instance of svccfg
Puppet::Type.type(:dns).provide(:dns,
                                :parent =>
Puppet::Type.type(:svccfg).provider(:svccfg)) do

  desc "Provider for management of DNS for Oracle Solaris"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :svccfg => '/usr/sbin/svccfg', :svcprop => '/usr/bin/svcprop'


  Dns_fmri = "svc:/network/dns/client"

  mk_resource_methods

  def self.instances
    props = {}
    svcprop("-p", "config", Dns_fmri).each_line do |line|
      fullprop, value = line.strip.split(" ", 3).values_at(0,2)
      prop = fullprop.split("/")[1].intern
      if Puppet::Type.type(:dns).validproperties.include? prop
        if [:options,:nameserver,:search,:sortlist].include? prop
          # remove escaped spaces, they are invalid in the resource
          # output and break automatic list munging
          value = value.gsub(/\\ /,' ')
        end
        props[prop] = value
      end
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

  Puppet::Type.type(:dns).validproperties.each do |field|
    prop_type = Puppet::Type::Dns.propertybyname(field).prop_type
    define_method(field.to_s + "=") do |should|
      begin
        value = munge_value(should,prop_type)
        svccfg("-s", Dns_fmri, "setprop", "config/#{field}=", value)
        return value
      rescue => detail
        fail "value: #{should.inspect}\n#{detail}\n"
      end
    end
  end

  def flush
    svccfg("-s", Dns_fmri, "refresh")
  end
end
