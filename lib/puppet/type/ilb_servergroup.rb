#
# Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
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


require File.expand_path(File.join(File.dirname(__FILE__), '..','..','puppet_x/oracle/solaris_providers/util/validation.rb'))

Puppet::Type.newtype(:ilb_servergroup) do
  @doc = "Manage Solaris Integrated Load Balancer (ILB) server group Gconfiguration."
  validator = PuppetX::Oracle::SolarisProviders::Util::Validation.new

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name for the server group"
  end

  newproperty(:server, :parent => Puppet::Property::List, :array_matching => :all) do
    desc <<-HEREDOC
    Array of Servers in the servergroup in the format hostspec[:portspec]
    Specifies a list of servers to be added to the server group.

    hostspec is a hostname or IP address. IPv6 addresses must be enclosed
    in brackets ([]) to distinguish them from “:portspec”

    portspec is a service name or port number. If the port number is not
    specified, a number in the range 1–65535 is used.
    HEREDOC

    # Only validating the hostspec here
    validate do |value|
      value.strip!
      _host = ""
      _port = ""
      if idx = value.index(']:')
        _host = value.slice(1,idx-1)
        _port = value.split(":")[-1]

        # Make sure we used all the characters
        if idx.length != _host.length + _port.length + 3
          fail "Could not consume entire value: #{value} got #{_host} #{port}"
        end
      else
        _host = value.split(":")[0]
      end
      unless ( validator.valid_hostname?(_host) || validator.valid_ip?(_host) )
        fail "Invalid host or IP #{_host}"
      end
    end
  end
end
