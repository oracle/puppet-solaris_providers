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

Puppet::Type.type(:protocol_properties).provide(:protocol_properties) do
    desc "Provider for managing Oracle Solaris protocol object properties"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
    commands :ipadm => '/usr/sbin/ipadm'

    mk_resource_methods

    def initialize(value={})
        super(value)
        @protoprops = {}
    end

    def self.instances
        props = Hash.new { |k,v| k[v] = Hash.new }
        ipadm("show-prop", "-c", "-o", "PROTO,PROPERTY,CURRENT").each_line do
          |line|
          protocol, property, value = line.strip.split(":")
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
      resources.keys.each { |key|
        things.find { |prop|
          prop.name == key
        }.tap { |provider|
          next if provider.nil?
          resources[key].provider = provider
        }
      }
    end

    def properties=(value)
        value.each do |key, val|
            ipadm("set-prop", "-p", "#{key}=#{val}", @resource[:name])
        end
    end

    def exists?
      @resource[:ensure] == :present
    end

    def create
      fail "protcol must exist"
    end
end
