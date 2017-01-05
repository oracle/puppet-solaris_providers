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

Puppet::Type.newtype(:process_scheduler) do
  @doc ="
  Manage Solaris process scheduler administration. See: dispadmin(8)
  It does not modify scheduler parameters. Once a scheduler has been set it
  cannot be unset by puppet.

  *NOTE* The name of the resource is always the literal string 'current'"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name for the resource. Always 'current'"
    newvalues(:current)
  end

  newproperty(:scheduler) do
    desc "The default scheduling class. See dispadmin(8). If no default scheduler
    has been set puppet resource returns the default value TS.

    RT for the real-time class

    TS for the time-sharing class (default)

    IA for the inter-active class

    FSS for  the fair-share  class

    FX for the fixed-priority class"
    newvalues(:RT,:TS,:IA,:FSS,:FX)
  end
end
