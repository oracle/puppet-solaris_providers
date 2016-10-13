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

Puppet::Type.newtype(:protocol_properties) do
    @doc = "Manage Oracle Solaris protocol properties"

    ensurable do
        # remove the ability to specify :absent.  New values must be set.
        newvalue(:present) do
            provider.create
        end
    end

    newparam(:protocol) do
        desc "The name of the protocol"
        isnamevar
    end

    newparam(:temporary) do
        desc "Optional parameter that specifies changes to the protocol are
              temporary.  Changes last until the next reboot."
        newvalues(:true, :false)
    end

    newproperty(:properties) do
        desc "A hash table of propname=propvalue entries to apply to an
              protocol. See ipadm(8)"

        def property_matches?(current, desired)
            desired.each do |key, value|
                if current[key] != value
                    return :false
                end
            end
            return :true
        end
    end
end
