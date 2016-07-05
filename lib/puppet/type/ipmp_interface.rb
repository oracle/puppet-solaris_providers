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

require 'puppet/property/list'

Puppet::Type.newtype(:ipmp_interface) do
    @doc = "Manage the configuration of Oracle Solaris IPMP interfaces"

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

    newproperty(:interfaces, :parent => Puppet::Property::List) do
        desc "An array of interface names to use for the IPMP interface"

        # ensure should remains an array
        def should
            @should
        end

        def insync?(is)
            is = [] if is == :absent or is.nil?
            is.sort == self.should.sort
        end

        # ipadm returns multivalue entries delimited with a space
        def delimiter
            " "
        end

        validate do |name|
            cmd = Array["/usr/sbin/ipadm", "show-if", "-p", "-o", "IFNAME"]
            output = Puppet::Util::Execution.execute(cmd).split("\n")
            if name.class == Array
                check = output - name
                unless check.empty?
                  fail "Invalid interface(s) specified: #{check.inspect}"
                end
            else
                unless output.include?(name)
                  fail "Invalid interface specified: #{name}"
                end
            end
        end
    end
end
