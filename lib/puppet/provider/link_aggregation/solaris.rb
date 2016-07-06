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
    dladm("show-aggr", "-p", "-o",
          "link,mode,policy,addrpolicy,lacpactivity,lacptimer").each_line
    .collect do |line|
      link, mode, policy, addrpolicy, lacpactivity, lacptimer = \
        line.chomp.split(":").map! { |e| ( e == "--" ) ? nil : e }

      links = []
      dladm("show-aggr", "-x", "-p", "-o", "port", link).split(
        "\n").each do |portline|
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
          :lacptimer => lacptimer)
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
    is_temporary?
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
    is_temporary?
    # -m was removed in s12_99; mode must be changed via destroy/create
    destroy
    create
    return @property_hash[:mode]= value
  end

  def policy=(value)
    is_temporary?
    dladm("modify-aggr", "-P", value, resource[:name])
    return @property_hash[:policy]= value
  end

  def lacpmode=(value)
    is_temporary?
    dladm("modify-aggr", "-L", value, resource[:name])
    return @property_hash[:lacpmode]= value
  end

  def lacptimer=(value)
    is_temporary?
    dladm("modify-aggr", "-T", value, resource[:name])
    return @property_hash[:lacptimer]= value
  end

  def address=(value)
    is_temporary?
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

  def is_temporary?
    dladm("show-aggr", "-P", name)
    #raise Puppet::Error, "Unable to change attributes of temporary " \
    #    "aggregation #{name} " if p[:exit] == 1
    nil
  end

  def exec_cmd(*cmd)
    output = Puppet::Util::Execution.execute(cmd, :failonfail => false)
    {:out => output, :exit => $CHILD_STATUS.exitstatus}
  end
end

