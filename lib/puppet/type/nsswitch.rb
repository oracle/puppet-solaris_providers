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

Puppet::Type.newtype(:nsswitch) do
    @doc = "Name service switch configuration data"

    newparam(:name) do
        desc "The symbolic name for the nsswitch settings to use.  This name
              is used for human reference only."
        isnamevar
    end

    newproperty(:default) do
        desc "The default configuration entry"
    end

    newproperty(:host) do
        desc "The host database lookup override"
    end

    newproperty(:password) do
        desc "The password database lookup override"
    end

    newproperty(:group) do
        desc "The group database lookup override"
    end

    newproperty(:network) do
        desc "The network database lookup override"
    end

    newproperty(:rpc) do
        desc "The rpc database lookup override"
    end

    newproperty(:ether) do
        desc "The ether database lookup override"
    end

    newproperty(:netmask) do
        desc "The netmask database lookup override"
    end

    newproperty(:bootparam) do
        desc "The bootparam database lookup override"
    end

    newproperty(:publickey) do
        desc "The publickey database lookup override"
    end

    newproperty(:netgroup) do
        desc "The netgroup database lookup override"
    end

    newproperty(:automount) do
        desc "The automount database lookup override"
    end

    newproperty(:alias) do
        desc "The alias database lookup override"
    end

    newproperty(:service) do
        desc "The service database lookup override"
    end

    newproperty(:project) do
        desc "The project database lookup override"
    end

    newproperty(:auth_attr) do
        desc "The auth_attr database lookup override"
    end

    newproperty(:prof_attr) do
        desc "The prof_attr database lookup override"
    end

    newproperty(:tnrhtp) do
        desc "The tnrhtp database lookup override.  Requires trusted extensions"
    end

    newproperty(:tnrhdb) do
        desc "The tnrhdb database lookup override.  Requires trusted extensions"
    end

    newproperty(:sudoer) do
        desc "The sudoer database lookup override.  Used with sudo only"
    end
end
