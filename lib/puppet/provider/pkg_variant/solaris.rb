#
# Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:pkg_variant).provide(:solaris) do
  desc "Provider for Oracle Solaris variants"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11']
  commands :pkg => '/usr/bin/pkg'

  def self.instances
    pkg(:variant, "-H", "-F", "tsv").split("\n").collect do |line|
      name, value = line.split
      new(:name => name,
          :ensure => :present,
          :value => value)
    end
  end

  def self.prefetch(resources)
    # pull the instances on the system
    variants = instances

    # set the provider for the resource to set the property_hash
    resources.keys.each do |name|
      if provider = variants.find{ |variant| variant.name == name}
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
      # cast @resource[:value] to a string since it gets translated to an
      # object by Puppet
      return (@property_hash[:ensure] == :present and \
              @property_hash[:value] == @resource[:value].to_s)
    end
    @property_hash[:ensure] == :present
  end

  def create
    pkg("change-variant", "#{@resource[:name]}=#{@resource[:value]}")
  end
end
