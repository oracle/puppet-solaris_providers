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

Puppet::Type.newtype(:solaris_vlan) do
  @doc = "Manage the configuration of Oracle Solaris VLAN links"

  ensurable

  newparam(:name) do
    desc "The name of the VLAN"
    isnamevar
  end

  newparam(:force) do
    desc "Optional parameter to force the creation of the VLAN link"
    newvalues(:true, :false)
  end

  newparam(:temporary) do
    desc "Optional parameter that specifies that the VLAN is
              temporary.  Temporary VLAN links last until the next reboot."
    newvalues(:true, :false)
  end

  newproperty(:lower_link) do
    desc "Specifies Ethernet link over which VLAN is created"
  end

  newproperty(:vlanid) do
    desc "VLAN link ID"
  end
end
