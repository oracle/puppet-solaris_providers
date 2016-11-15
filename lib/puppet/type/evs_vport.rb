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

Puppet::Type.newtype(:evs_vport) do
    @doc = "Manage the configuration of EVS VPort"

    ensurable do
        newvalue(:present) do
            provider.create
        end

        newvalue(:absent) do
            provider.destroy
        end

        # Resets the specified VPort
        newvalue(:reset) do
            provider.reset
        end
    end

    newparam(:name) do
        desc "The full name of Virtual Port for EVS"
        munge do |value|
            if value.split("/").length != 3
                raise Puppet::Error, "Invalid VPort name\n" \
                    "Name convention must be <tenant>/<evs>/<vport>"
            else
                value
            end
        end
    end

    ## read/write properties (always updatable) ##
    newproperty(:cos) do
        desc "802.1p priority on outbound packets on the virtual port"
    end

    newproperty(:maxbw) do
        desc "The full duplex bandwidth for the virtual port"
    end

    newproperty(:priority) do
        desc "Relative priority of virtual port"
        newvalues("high", "medium", "low", "")
    end

    newproperty(:protection) do
        desc "Enables one or more types of link protection"
        # verify protection value: comma(,) separable
        validate do |value|
            value.split(",").collect do |each_val|
                if not ["mac-nospoof", "restricted", "ip-nospoof",
                    "dhcp-nospoof", "none", ""].include? each_val
                    raise Puppet::Error, "Invalid value \"#{each_val}\". "\
                        "Valid values are mac-nospoof, restricted, "\
                        "ip-nospoof, dhcp-nospoof, none."
                end
            end
        end
    end

    ## read-only properties (Settable upon creation) ##
    newproperty(:ipaddr) do
        desc "The IP address associated with the virtual port"
    end

    newproperty(:macaddr) do
        desc "The MAC address associated with the virtual port"
    end

    newproperty(:uuid) do
        desc "UUID of the virtual port"
    end
end
