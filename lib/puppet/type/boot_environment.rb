#
#
# Copyright [yyyy] [name of copyright owner]
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

#
# Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved.
#

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
        desc "Description for the new BE"
    end

    newparam(:clone_be) do
        desc "Create a new BE from an existing inactive BE"
    end

    newparam(:options) do
        desc "Create the datasets for a new BE with specific ZFS
              properties.  Specify options as a hash."
    end

    newparam(:zpool) do
        desc "Create the new BE in the specified zpool"
    end

    newproperty(:activate) do
        desc "Activate the specified BE"
        newvalues(:true, :false)
    end
end
