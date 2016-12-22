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

Puppet::Type.newtype(:address_properties) do
  @doc = "Manage Oracle Solaris address properties"

  ensurable do
    # remove the ability to specify :absent.  New values must be set.
    newvalue(:present) do
      provider.create
    end
  end

  newparam(:address) do
    desc "The name of the address object"
    isnamevar
  end

  newparam(:temporary) do
    desc "Optional parameter that specifies changes to the address object
              are temporary.  Changes last until the next reboot."
    newvalues(:true, :false)
  end

  newproperty(:properties) do
    desc "A hash table of propname=propvalue entries to apply to an
              address object. See ipadm(8)"

    def insync?(is)
      is = [] if is == :absent or is.nil?
      return false unless is.length == should.length
      is.zip(@should).all? {|a, b| property_matches?(a, b) }
    end
  end

  autorequire(:address_object) do
    children = catalog.resources.select { |resource|
      resource.type == :address_object &&
        self[:address].include?(resource[:name])
    }
    children.each.collect { |child|
      child[:name]
    }
  end
end
