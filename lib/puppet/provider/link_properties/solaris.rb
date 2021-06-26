#
# Copyright (c) 2013, 2017, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:link_properties).provide(:solaris) do
  desc "Provider for managing Oracle Solaris link properties"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11']
  commands :dladm => '/usr/sbin/dladm'

  mk_resource_methods

  def initialize(value={})
    super(value)
    @linkprops = {}
  end

  def self.instances
    links = Hash.new{ |h,k| h[k] = {} }
    dladm("show-linkprop", "-c", "-o",
          'LINK,PROPERTY,PERM,VALUE,DEFAULT,POSSIBLE').
      each_line do |line|
      line = line.gsub('\\:','%colon%')
      link,prop,perm,value,_default,_possible = line.split(":")
      next if perm != 'rw'
      value = value.gsub('%colon%',':')
      if value.empty?
        value = :absent
        value = _default unless _default.empty?
      end
      links[link][prop] = value
    end

    links.each_pair.collect do |link,props|
      new(:name => link,
          :ensure => :present,
          :properties => props)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def properties=(value)
    dladm("set-linkprop", *add_properties(value), @resource[:name])
  end

  def add_properties(props=@resource[:properties])
    a = []
    props.each do |key, value|
      a << "#{key}=#{value}"
    end
    properties = Array["-p", a.join(",")]
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    # Cannot create link props. They must already exist
    fail("Link must exist for properties to be set.")
  end
end
