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

Puppet::Type.type(:link_aggregation).provide(:link_aggregation) do
  desc "Provider for creating Oracle Solaris link aggregations"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :dladm => '/usr/sbin/dladm'

  mk_resource_methods

  def self.instances
    persistent = []
    dladm("show-aggr", "-P", "-p", "-o", "link").each_line.collect do |line|
      persistent << line.chomp.strip()
    end

    dladm("show-aggr", "-p", "-o",
          "link,mode,policy,addrpolicy,lacpactivity,lacptimer").
          each_line.collect do |line|
           link, mode, policy, addrpolicy, lacpactivity, lacptimer = \
             line.chomp.split(":").map! { |e| ( e == "--" ) ? nil : e }

           links = []
           dladm("show-aggr", "-x", "-p", "-o", "port", link).
             each_line do |portline|
             next if portline.strip() == ""
             links << portline.chomp.strip()
           end

           new(:name => link,
               :ensure => :present,
               :lower_links => links,
               :mode => mode,
               :policy => policy,
               :address => addrpolicy,
               :lacpmode => lacpactivity,
               :lacptimer => lacptimer,
               :temporary => persistent.include?(link) ? :false : :true
              )
         end
  end

  def self.prefetch(resources)
    # pull the instances on the system
    aggrs = instances

    # set the provider for the resource to set the property_hash
    resources.keys.each do |name|
      if provider = aggrs.find{ |aggr| aggr.name == name}
        resources[name].provider = provider
      end
    end
  end

  # override mk_resource_method  property setters
  def lower_links=(value)
    recreate_temporary && return
    current = lower_links.kind_of?(Array) ? lower_links : []
    remove_list = []
    for entry in current - value
      @property_hash[:lower_links].delete entry
      remove_list << "-l" << entry
    end

    add_list = []
    for entry in value - current
      @property_hash[:lower_links].push entry
      add_list << "-l" << entry
    end

    unless add_list.empty?
      dladm("add-aggr", *add_list, name)
    end

    unless remove_list.empty?
      dladm("remove-aggr", *remove_list, name)
    end
    return @property_hash[:lower_links]
  end

  def mode=(value)
    # -m was removed in s12_99; mode must be changed via destroy/create
    destroy
    create
    return @property_hash[:mode]= value
  end

  def policy=(value)
    recreate_temporary && return
    dladm("modify-aggr", "-P", value, resource[:name])
    return @property_hash[:policy]= value
  end

  def lacpmode=(value)
    recreate_temporary && return
    dladm("modify-aggr", "-L", value, resource[:name])
    return @property_hash[:lacpmode]= value
  end

  def lacptimer=(value)
    recreate_temporary && return
    dladm("modify-aggr", "-T", value, resource[:name])
    return @property_hash[:lacptimer]= value
  end

  def address=(value)
    recreate_temporary && return
    dladm("modify-aggr", "-u", value, resource[:name])
    return @property_hash[:address]= value
  end

  def add_options
    options = []
    if resource[:temporary] == :true
      options << "-t"
    end

    if lowerlinks = resource[:lower_links]
      if lowerlinks.is_a? Array
        for link in lowerlinks
          options << "-l" << link
        end
      else
        options << "-l" << lowerlinks
      end
    end

    if mode = resource[:mode]
      options << "-m" << mode
    end

    if policy = resource[:policy]
      options << "-P" << policy
    end

    if lacpmode = resource[:lacpmode]
      options << "-L" << lacpmode
    end

    if lacptimer = resource[:lacptimer]
      options << "-T" << lacptimer
    end

    if address = resource[:address]
      options << "-u" << address
    end
    options
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    dladm("create-aggr", *add_options, resource[:name])
    @property_hash.merge!(resource)
    nil
  end

  def destroy
    dladm("delete-aggr", resource[:name])
    @property_hash[:ensure]=:absent
    nil
  end

  def recreate_temporary
    # Temporary aggregations cannot be modified, instead of failing and
    # forcing them to be removed if changes are desired remove and re-create
    # the aggregation
    if resource[:temporary] == :true
      destroy
      create
      return true
    else
      return false
    end
  end
end

