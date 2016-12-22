#
# Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.newtype(:ipmp_interface) do
  @doc = "Manage the configuration of Oracle Solaris IPMP interfaces"

  ensurable

  newparam(:name) do
    desc "The name of the IP interface"
    isnamevar
  end

  newproperty(:temporary)  do
    desc "Optional parameter that specifies that the IP interface is
              temporary.  Temporary interfaces last until the next reboot.
              Temporary interfaces cannot be modified in place. They will be
              removed and recreated"
    newvalues(:true, :false)
  end

  # This is a Puppet::Property::List but that breaks on internal
  # representation as an Array
  newproperty(:interfaces) do
    desc "An array of interface names to use for the IPMP interface"

    # This doesn't seem to catch 'aaa' or 'Net0'
    newvalues(/^[a-z][a-z_0-9]+[0-9]+$/)

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

    validate do |value|
      unless (3..16).include? value.length
        fail "Invalid interface '#{value}' must be 3-16 characters"
      end
      unless /^[a-z][a-z_0-9]+[0-9]+$/.match(value)
        fail "Invalid interface name '#{value}' must match a-z _ 0-9"
      end
    end
  end

  autorequire(:ip_interface) do
    children = catalog.resources.select { |resource|
      resource.type == :ip_interface &&
        self[:interfaces].include?(resource[:name])
    }
    children.each.collect { |child|
      child[:name]
    }
  end
end
