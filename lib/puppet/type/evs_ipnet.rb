#
# Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.newtype(:evs_ipnet) do
    @doc = "Manage the configuration of IPnet (subnet of IPv4 or IPv6
            addresses)"

    ensurable
    newparam(:name) do
        desc "The full name of IPnet including tenant name"
        validate do |value|
            if value.split("/").length != 3
                raise Puppet::Error, "Invalid IPnet name\n"\
                    "Name convention must be <tenant>/<evs>/<ipnet>"
            end
        end
    end

    ## read-only properties (updatable when idle) ##
    newproperty(:subnet) do
        desc "Subnet (either IPv4 or IPv6) for the IPnet"
    end

    newproperty(:defrouter) do
        desc "The IP address of the default router for the given IPnet"
    end

    newproperty(:uuid) do
        desc "UUID of the IPnet"
    end

    ## read/write property (settable upon creation) ##
    newproperty(:pool) do
        desc "Sub-ranges of IP addresses within a subnet"
    end
end
