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
  @doc = <<-HEREDOC
  Manage Solaris Integrated Load Balancer (ILB) back end server configuration.
  Backend servers can only belong to one server group and are internally identified as
  the combination of server and server group.

  ** Note **
  Creation of server groups without assigned rules will result in catalog
  changes for every run as puppet tries to enable the server.
  HEREDOC

  validator = PuppetX::Oracle::SolarisProviders::Util::Validation.new

  ensurable

  def self.title_patterns
    [
      [%r((^(.+)\|(.+)\|(.+))$),[:name,:servergroup,:server,:port]],
      [%r((^(.+)\|(.+))$),[:name,:servergroup,:server]],
      [%r(.+),[:name]]
    ]
  end

  newparam(:name, :namevar => true) do
    desc <<-HEREDOC
    Name for the server, The name of the server definition is arbitrary.
    ** Title Patterns **
    Strings which do not match the pattern will only populate the name
    Specific patterns will be split to auto populate fields
      <servergroup>|<server>
      <servergroup>|<server>|<port>
    HEREDOC
  end

  newproperty(:server) do
    desc <<-HEREDOC
    IP of the ILB back end server

    Server is a hostspec in the format hostname or IP address.
    HEREDOC

    munge do |value|
      return value if value[0] == '['
      if validator.valid_ipv6?(value)
        value.insert(0,'[')
        value.insert(-1,']')
      end
      value
    end

    validate do |value|
      value.strip!
      if value[0] == '['
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
    Port is the service name or port number to use for the back end server.

    Port is a service name, port number, or range port-port. If the port
    number is not specified, a number in the range 1–65535 is used.

    ** Note **
    The use of numerical ports is recommended. Service names are not
    validated at compilation time and may fail on individual nodes.

    HEREDOC
    validate do |value|
        PuppetX::Oracle::SolarisProviders::Util::Ilb.valid_portspec?(value)
    end
  end

  newproperty(:servergroup) do
    desc <<-HEREDOC
    Servergroup is the name of the server group this server definition
    belongs to. Servers may be defined in multiple server groups.

    ** Autorequires **
    Server group will automatically require any matching ilb_servergroup
    resource.
    HEREDOC

    validate do |value|
      fail "Must be defined" unless value
      fail "Must be defined" unless value.match(/\p{Alnum}/)
    end
  end

  newproperty(:enabled) do
    desc "Should this server be enabled.
    If this server is a member of an unassigned servergroup the value
    will be unassigned.

    **Note:** It it not possible to create a sever in the disabled state."
    newvalues(:true,:false,:unassigned)
  end

  newparam(:sid) do
    desc "System generated ServerID. Value is ignored if manually specified"
  end

  autorequire(:ilb_servergroup) do
    [self[:servergroup]]
  end

end
