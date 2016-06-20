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

require 'puppet/property/list'

Puppet::Type.newtype(:link_aggregation) do
    @doc = "Manage the configuration of Oracle Solaris link aggregations"

    ensurable

    newparam(:name) do
        desc "The name of the link aggregration"
        isnamevar
    end

    newparam(:temporary) do
        desc "Optional parameter that specifies that the aggreation is
              temporary.  Temporary aggregation links last until the next
              reboot."
        newvalues(:true, :false)
    end

    newproperty(:lower_links, :parent => Puppet::Property::List) do
        desc "Specifies an array of links over which the aggrestion is created."

        # ensure should remains an array
        def should
            @should
        end

        def insync?(is)
            is = [] if is == :absent or is.nil?
            is.sort == self.should.sort
        end

        # dladm returns multivalue entries delimited with a space
       # def delimiter
       #     " "
       # end

    end

    newproperty(:mode) do
        desc "Specifies which mode to set."
        newvalues(:trunk, :dlmp)
    end

    newproperty(:policy) do
        desc "Specifies the port selection policy to use for load spreading
              of outbound traffic."
    end

    newproperty(:lacpmode) do
        desc "Specifies whether LACP should be used and, if used, the mode
              in which it should operate"
        newvalues(:off, :active, :passive)
    end

    newproperty(:lacptimer) do
        desc "Specifies the LACP timer value"
        newvalues(:short, :long)
    end

    newproperty(:address) do
        desc "Specifies a fixed unicast hardware address to be used for the
              aggregation"
    end
end
