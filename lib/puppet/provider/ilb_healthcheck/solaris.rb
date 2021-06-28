
#
# Copyright (c) 2016, 2021, Oracle and/or its affiliates.
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

Puppet::Type.type(:ilb_healthcheck).provide(:solaris) do
  @doc = "Provider to manage Solaris Integrated Load Balancer (ILB) health checks."
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11']
  commands :ilbadm => '/usr/sbin/ilbadm'

  mk_resource_methods

  def self.instances
    checks=[]

    ilbadm('show-healthcheck').each_line do |line|
      next if line =~ /^HCNAME/
      name, timeout, count, interval, default_ping, test = line.strip.split(/\s+/,6)
      checks.push(
        new(:name => name,
            :timeout => timeout,
            :count => count,
            :interval => interval,
            :default_ping => (default_ping == "Y" ? :true : :false),
            :test => test,
            :ensure => :present)
      )
    end
    return checks
  end

  def self.prefetch(resources)
    _instances = instances
    resources.keys.each do |name|
      if provider = _instances.find { |_resource| _resource.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    _args = []

    if @resource[:default_ping] == :false
      _args.push "-n"
    end

    _arg_str = [:timeout, :count, :interval, :test].each.collect do |thing|
      if @resource[thing] && @resource[thing] != :absent
        "hc-#{thing}=#{@resource[thing]}"
      end
    end

    _args.push('-h',_arg_str.compact.join(','))

    ilbadm('create-healthcheck', *_args, @resource[:name] )
    nil
  end

  def destroy
    ilbadm("delete-healthcheck", @resource[:name])
  end

  [
    :timeout, :count, :interval, :test, :default_ping
  ].each do |method|
    define_method("#{method}=") do |should|
      destroy
      create
      @property_hash[method] = should
    end
  end
end
