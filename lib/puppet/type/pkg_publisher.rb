#
# Copyright (c) 2013, 2015, Oracle and/or its affiliates. All rights reserved.
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

require 'puppet/property/list'
Puppet::Type.newtype(:pkg_publisher) do
    @doc = "Manage Oracle Solaris package publishers"

    ensurable

    newparam(:name) do
        desc "The publisher name"
        isnamevar
    end

    newproperty(:origin, :parent => Puppet::Property::List) do
        desc "Which origin URI(s) to set.  For multiple origins, specify them
              as a list"

        # ensure should remains an array
        def should
            @should
        end

        def insync?(is)
            is = [] if is == :absent or is.nil?
            is.sort == self.should.sort
        end

        def retrieve
            provider.origin
        end

        # for origins with a file:// URI, strip any trailing / character
        munge do |value|
            if value.start_with? "file" and value.end_with? "/"
                value = value.chomp("/")
            else
                value
            end
        end
    end
    newproperty(:enable) do
        desc "Enable the publisher"
        newvalues(:true, :false)
    end

    newproperty(:sticky) do
        desc "Set the publisher 'sticky'"
        newvalues(:true, :false)
    end

    newproperty(:searchfirst) do
        desc "Set the publisher first in the search order"
        newvalues(:true)
    end

    newproperty(:searchafter) do
        desc "Set the publisher after the specified publisher in the search
              order"
    end

    newproperty(:searchbefore) do
        desc "Set the publisher before the specified publisher in the search
              order"
    end

    newproperty(:proxy) do
        desc "Use the specified web proxy URI to retrieve content for the
              specified origin or mirror"
    end

    newproperty(:sslkey) do
        desc "Specify the client SSL key"
    end

    newproperty(:sslcert) do
        desc "Specify the client SSL certificate"
    end

    newproperty(:mirror, :parent => Puppet::Property::List) do
        desc "Which mirror URI(s) to set.  For multiple mirrors, specify them
              as a list"

        # ensure should remains an array
        def should
            @should
        end

        def insync?(is)
            is = [] if is == :absent or is.nil?
            is.sort == self.should.sort
        end

        def retrieve
            provider.mirror
        end

        munge do |value|
            if value.start_with? "file" and value.end_with? "/"
                value = value.chomp("/")
            else
                value
            end
        end
    end
end
