#
# Copyright (c) 2013, 2014, Oracle and/or its affiliates. All rights reserved.
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
              reboot. Attempts to modify temporary aggregations will result
              in the aggregation being removed and re-created"
    newvalues(:true, :false)
  end

  # This is a Puppet::Property::List but that breaks on internal
  # representation as an Array
  newproperty(:lower_links) do
    desc "Specifies an array of links over which the aggrestion is created.

     Modifying a partially defined pre-existing resource is not recommended.
     As incompatible option combinations cannot be verified before
     application.
    "

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.sort == self.should.sort
    end

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

  newproperty(:mode) do
    desc "Specifies which mode to set. Mode can not be changed on an
        existing aggregation, instead the aggregation will be removed and
        re-created.
    "
    newvalues(:trunk, :dlmp)
  end

  newproperty(:policy) do
    desc "Specifies the port selection policy to use for load spreading
              of outbound traffic."
    newvalues("L2","L3","L4","L2,L3")
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
              newvalues(/^(?:\p{Xdigit}{1,2}:){5}\p{Xdigit}{1,2}$/,:auto)
  end
  autorequire(:ip_interface) do
    children = catalog.resources.select { |resource|
      resource.type == :ip_interface &&
        self[:lower_links].include?(resource[:name])
    }
    children.each.collect { |child|
      child[:name]
    }
  end

  validate {
    if (self[:mode] != :absent || self[:mode].nil?) &&
       (self[:lower_links] == :absent || self[:lower_links].nil?)
        fail "lower_links must be defined when mode is specified"
      end
  }

end
