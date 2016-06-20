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
# Copyright (c) 2013, 2014, Oracle and/or its affiliates. All rights reserved.
#

Puppet::Type.newtype(:ip_interface) do
    @doc = "Manage the configuration of Oracle Solaris IP interfaces"

    ensurable

    newparam(:name) do
        desc "The name of the IP interface"
        isnamevar
    end

    newparam(:temporary)  do
        desc "Optional parameter that specifies that the IP interface is
              temporary.  Temporary interfaces last until the next reboot."
        newvalues(:true, :false)
    end
end
