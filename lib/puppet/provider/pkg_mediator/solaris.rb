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

Puppet::Type.type(:pkg_mediator).provide(:pkg_mediator) do
  desc "Provider for Oracle Solaris mediators"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :pkg => '/usr/bin/pkg'
  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = { :set_args => [], :unset_args => [] }
  end

  def self.parse_mediator(line)
    name, _ver_src, version, _impl_src, impl, _impl_ver = line.split("\t")

    # Neither Implementation nor Version are required
    if impl.nil? || impl.empty?
      impl = :None
    end
    if version.nil? || version.empty?
      version = :None
    end

    return { :name => name,
             :ensure => :present,
             :implementation => impl,
             :version => version }
  end

  def self.get_mediator(name)
    return self.parse_mediator(pkg(:mediator, "-H", "-F", "tsv", name))
  end

  def self.instances
    pkg(:mediator, "-H", "-F", "tsv").split("\n").collect do |line|
      new(self.parse_mediator(line))
    end
  end

  def self.prefetch(resources)
    # pull the instances on the system
    mediators = instances

    # set the provider for the resource to set the property_hash
    resources.keys.each do |name|
      if provider = mediators.find{ |mediator| mediator.name == name}
        resources[name].provider = provider
      end
    end
  end

  def exists?
    if @property_hash[:ensure] == :present and not
      # Don't check values unless they are set in the manifest/resource
      ( @resource[:version].nil? && @resource[:implementation].nil? )
      # Both Version and Implementation must be expected or unspecified
      return ((version == @resource[:version]) ||
              @resource[:version].nil? ) \
             &&
             ((implementation == @resource[:implementation] ||
               @resource[:implementation].nil?))
    end
    @property_hash[:ensure] == :present
  end

  def build_flags
    if version == @resource[:version]
    # Current State is Correct, noop
    elsif @resource[:version] == :None && version != :None
      # version is set and should not be
      @property_flush[:unset_args] << '-V'
    elsif ! @resource[:version].nil?
      @property_flush[:set_args] << '-V' << @resource[:version]
    end

    if implementation == @resource[:implementation]
    # Current State is Correct, noop
    elsif @resource[:implementation] == :None && implementation != :None
      # implementation is set and should not be
      @property_flush[:unset_args] << '-I'
    elsif ! @resource[:implementation].nil?
      @property_flush[:set_args] << '-I' << @resource[:implementation]
    end

    # If there is no pre-existing resource there will be no properties
    # defined. If we got here and set_args is 0 we have unset_args
    # otherwise there would be no changes
    if @property_hash[:ensure].nil? && @property_flush[:set_args].empty?
      raise Puppet::ResourceError.new(
        "Cannot unset absent mediator; use ensure => :absent instead of <property> => None"
      )
    end
  end

  def flush
    pkg("set-mediator", @property_flush[:set_args], @resource[:name]) unless
      @property_flush[:set_args].empty?
    pkg("unset-mediator", @property_flush[:unset_args], @resource[:name]) unless
      @property_flush[:unset_args].empty?
    @property_hash = self.class.get_mediator(resource[:name])
  end

  # required puppet functions
  def create
    build_flags
  end

  def destroy
    # Absent mediators don't require any flag parsing, just remove them
    pkg("unset-mediator", @resource[:name])
  end
end
