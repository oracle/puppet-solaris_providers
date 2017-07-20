#
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:process_scheduler).provide(:solaris) do
  @doc = "Provider to manage Solaris process scheduler"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :dispadmin => '/usr/sbin/dispadmin'

  mk_resource_methods

  def self.instances
    begin
      sched = dispadmin("-d").split[0]
    rescue Puppet::ExecutionFailure
      if $!.to_s =~ /class is not set/
        # with no default scheduler set dispadmin exits 1
        sched = "TS"
      else
        raise
      end
    end
    [
      new(:name => 'current',
       :scheduler => sched,
       :ensure => :present)
    ]
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

  def scheduler=(value)
      dispadmin("-d", value)
      return value
  end

  def exists?
    # This could just always return true
    @property_hash[:ensure] == :present
  end

  def create
    fail "Cannot create"
  end

  def destroy
    fail "Cannot destroy"
  end
end
