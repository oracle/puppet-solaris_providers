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

Puppet::Type.newtype(:link_properties) do
  @doc = "Manage Oracle Solaris link properties"

  ensurable

  newparam(:link) do
    desc "The name of the link"
    isnamevar
  end

  newparam(:temporary) do
    desc "Optional parameter that specifies changes to the link are
              temporary.  Changes last until the next reboot."
    newvalues(:true, :false)
  end

  newproperty(:properties) do
    desc "A hash table of propname=propvalue entries to apply to the link. See ipadm(8)"

    def insync?(is)
      # There will almost always be more properties on the system than
      # defined in the resource. Make sure the properties in the resource
      # are insync
      should.each_pair { |prop,value|
        return false unless is.has_key?(prop)
        # Stop after the first out of sync property
        return false unless property_matches?(is[prop],value)
      }
      true
    end

    validate do |value|
      fail "must be a Hash" unless value.kind_of?(Hash)
      fail "Hash cannot be empty" if value.empty?
    end
  end
end
