#
# Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.newtype(:vnic) do
  @doc = "Manage the configuration of Oracle Solaris Virtual NICs (VNICs)"

  ensurable

  newparam(:name) do
    desc "The name of the VNIC"

    isnamevar

    validate do |vnic_value|
      if not vnic_value =~ /^[[:alpha:]]([\w.]){1,29}([\d])$/i
        raise Puppet::Error, "Invalid VNIC name: #{vnic_value}"
      end
    end
  end

  newparam(:temporary)  do
    desc "Optional parameter that specifies that  the  VNIC  is  temporary.
              Temporary VNICs last until the next reboot."
    newvalues(:true, :false)
  end

  newproperty(:lower_link) do
    desc "The name of the physical datalink over which the VNIC is
              operating"
    validate do |link_value|
      if not link_value =~ /^[[:alpha:]]([\w.]){1,29}([\d])$/i
        raise Puppet::Error, "Invalid lower-link: #{link_value}"
      end
    end
  end

  newproperty(:mac_address) do
    desc "Sets the VNIC's MAC address based on  the  specified value."
    validate do |mac_value|
      if not mac_value =~ /^([[:xdigit:]]{1,2}[:-]){5}[[:xdigit:]]{1,2}$/i
        raise Puppet::Error, "Invalid MAC address: #{mac_value}"
      end
    end
  end
end
