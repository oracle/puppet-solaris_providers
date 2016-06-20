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

Puppet::Type.newtype(:pkg_mediator) do
    @doc = "Manage Oracle Solaris package mediators"

    ensurable

    newparam(:name) do
        desc "The mediator name"
        isnamevar
    end

    newproperty(:version) do
        desc "The version of the mediated interface to use"
        newvalues(/none/io,/\A\d+(?:\.\d+){0,}\Z/)
        munge do |value|
          return value.downcase.capitalize.to_sym if value.match(/none/i)
          value
        end
    end

    newproperty(:implementation) do
        desc "The implementation of the mediated interface to use"
        newvalues(/none/io,/\A[[:alnum:]]+\Z/,/\A[[:alnum:]]+@(?:\d+(?:\.\d+){0,})\Z/)
        munge do |value|
          return value.downcase.capitalize.to_sym if value.match(/none/i)
          value
        end
    end

    validate {
      if self[:version] == :None && self[:implementation] == :None
        fail("Version and Implementation cannot both be :None use ensure => :absent instead")
      end
    }
end
