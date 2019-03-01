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

Puppet::Type.type(:pkg_facet).provide(:solaris) do
  desc "Provider for Oracle Solaris facets"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :pkg => '/usr/bin/pkg'

  # Defined classvar once. Access must be via Klass.send to prevent
  # undefined method `class_variable_get' errors
  Puppet::Type::Pkg_facet::ProviderSolaris.send(:class_variable_set, :@@classvars, {:changes => []})

  def self.instances
    pkg(:facet, "-H", "-F", "tsv").split("\n").collect do |line|
      name, value = line.split
      new(:name => name,
          :ensure => :present,
          :value => value.downcase)
    end
  end

  def self.prefetch(resources)
    # pull the instances on the system
    facets = instances

    # set the provider for the resource to set the property_hash
    resources.keys.each do |name|
      if provider = facets.find{ |facet| facet.name == name}
        resources[name].provider = provider
      end
    end
  end

  def value
    @property_hash[:value]
  end

  def exists?
    # only compare against @resource if one is provided via manifests
    if @property_hash[:ensure] == :present and @resource[:value] != nil
      # retrieve the string representation of @resource[:value] since it
      # gets translated to an object by Puppet
      return (@property_hash[:ensure] == :present &&
              @property_hash[:value].casecmp(@resource[:value]).zero?)
    end
    @property_hash[:ensure] == :present
  end

  def defer(arg)
    Puppet.debug "Defering facet: #{arg}"
    cv = Puppet::Type::Pkg_facet::ProviderSolaris.send(:class_variable_get, :@@classvars)
    cv[:changes].push arg
    Puppet::Type::Pkg_facet::ProviderSolaris.send(:class_variable_set, :@@classvars, cv)
  end

  def self.post_resource_eval
    # Apply any stashed changes and remove the class variable
    cv = Puppet::Type::Pkg_facet::ProviderSolaris.send(:class_variable_get, :@@classvars)
    # If changes have been stashed apply them
    unless cv[:changes].empty?
      Puppet.debug("Applying %s defered facet changes" % cv[:changes].length)
      pkg("change-facet", cv[:changes])
    end

    # Cleanup our tracking class variable
    Puppet::Type::Pkg_facet::ProviderSolaris.send(:remove_class_variable, :@@classvars)
  end

  # required puppet functions
  def create
    defer "#{@resource[:name]}=#{@resource[:value]}"
  end

  def destroy
    defer "#{@resource[:name]}=None"
  end
end
