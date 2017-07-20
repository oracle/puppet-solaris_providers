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

Puppet::Type.type(:protocol_properties).provide(:solaris) do
  desc "Provider for managing Oracle Solaris protocol object properties"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :ipadm => '/usr/sbin/ipadm'

  mk_resource_methods

  def self.instances
    props = Hash.new { |k,v| k[v] = Hash.new }
    ipadm("show-prop", "-c", "-o",
          "PROTO,PROPERTY,CURRENT,DEFAULT,PERSISTENT,POSSIBLE,PERM")
      .each_line do |line|
      protocol, property, value, _tmp = line.strip.split(':',4)
      props[protocol][property] = value ? value : :absent
    end

    protocols = []
    props.each do |key, value|
      protocols << new(:name => key,
                       :ensure => :present,
                       :properties => value)
    end
    protocols
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

  # Return an array of prop=value strings to change
  def change_props
    out_of_sync=[]
    # Compare the desired values against the current values
    resource[:properties].each_pair do |prop,should_be|
      is = properties[prop]
      # Current Value == Desired Value
      unless is == should_be
        # Stash out of sync property
        out_of_sync.push("%s=%s" % [prop, should_be])
      end
    end
    out_of_sync
  end

  def properties=(value)
    change_props.each do |prop|
      ipadm("set-prop", "-p", prop, @resource[:name])
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    fail "protcol must exist before properties can be set"
  end
end
