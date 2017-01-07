#
# Copyright (c) 2013, 2017 Oracle and/or its affiliates. All rights reserved.
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

require 'shellwords'
Puppet::Type.newtype(:boot_environment) do
  @doc = "Manage Oracle Solaris Boot Environments (BEs)"

  ensurable

  newparam(:name) do
    desc "The BE name"
    validate do |value|
      raise Puppet::Error, "Invalid BE name:  #{value}" unless
        value =~ /^[\d\w\.\-\:\_]+$/
    end
    isnamevar
  end

  newparam(:description) do
    desc "Description for the new BE. Description cannot be changed after BE
    creation."
    newvalues(/^[\s\p{Alnum}\-\:\_\.]+$/)
  end

  newparam(:clone_be) do
    desc "Create a new BE from an existing inactive BE or BE@snapshot.
      Clone BE cannot be changed after BE creation."
    newvalues(/^[\p{Alnum}\-\:\_\.]+(?:@[\p{Alnum}\-\:\_\.]+)?$/)
  end

  newparam(:options) do
    desc "Create the datasets for a new BE with specific zfs(8)
              properties.  Specify options as a hash.
    Properties are not synchronized after BE creation.
    "
    munge do |value|
      value.each_pair { |key,val|
        value[key] = val.shellescape
      }
    end
    validate do |value|
      fail "Invalid must be a Hash" unless value.kind_of?(Hash)

      value.keys.each { |key|
        unless key.match(/^[\p{Alnum}\-\:\_\.]+$/)
          fail "Invalid option '#{key}' must be ALNUM - : _ ."
        end
      }
    end
  end

  newparam(:zpool) do
    desc "Create the new BE in the specified zpool. Zpool is ignored for
        a cloned BE. Zpool cannot be changed after BE creation."
    newvalues(/^[\p{Alnum}\-\:\_\.]+$/)
  end

  newproperty(:running) do
    desc "An existing BE may be Active and/or Running. This parameter has no
          effect on behavior and exists only for display purposes."
    newvalues(:true,:false)
  end

  newproperty(:activate) do
    desc "Activate the specified BE. Only one BE may be active at a time.
    Activating an instance does not reboot the system to change the running BE."
    newvalues(:true, :false)
  end

  validate {
    if self[:clone_be] && self[:zpool]
      warning "zpool is ignored when cloning a BE"
    end
  }
end
