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
require File.expand_path(File.join(File.dirname(__FILE__), '..','..','puppet_x/oracle/solaris_providers/util/ilb.rb'))
require 'puppet/property/list'

Puppet::Type.newtype(:ilb_server) do
  @doc = "Manage Solaris Integrated Load Balancer (ILB) back end server configuration.
  Backend servers can only belong to one servergroup and are internally identified as
  the combination of server and server group.
  "
  validator = PuppetX::Oracle::SolarisProviders::Util::Validation.new

  ensurable

  # XXX add title patterns

  newparam(:name, :namevar => true) do
    desc <<-HEREDOC
    Name for the server, The name of the server definition is aribitrairy.
    ** Title Patterns **
    Strings which do not match the pattern will only populate the name
    Specific patterns will be split to auto populate fields
      <servergroup>|<server>
      <servergroup>|<server>|<port>
    HEREDOC
  end

  #XXX ensure present, absent, disabled, enabled

  newproperty(:server) do
    desc <<-HEREDOC
    IP of the ILB back end server

    Server is a hostspec in the format hostname or IP address.
    HEREDOC

    # Only validating the hostspec and numerical portspec
    # string portspecs are passed through
    validate do |value|
      value.strip!
      if value[-1] == ']'
        # IPv6 hostspec only
        _host = value.tr('[]','')
      else
        _host = value
      end
      unless ( validator.valid_hostname?(_host) || validator.valid_ip?(_host) )
        fail "Invalid host or IP #{_host}"
      end
    end
  end

  newproperty(:port) do
    desc <<-HEREDOC
    Port is the service name or port number to use for the backend server.

    Port is a service name, port number, or range port-port. If the port number is not
    specified, a number in the range 1–65535 is used.

    Service names are not validated.
    HEREDOC
    validate do |value|
        PuppetX::Oracle::SolarisProviders::Util::Ilb.valid_portspec?(value)
    end
  end

  newproperty(:servergroup) do
    desc <<-HEREDOC
    Servergroup is the name of the servergroup this server definition belongs to
    HEREDOC
  end

  # XXX autorequire servergroup
end
