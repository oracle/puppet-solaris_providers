#
# Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.newtype(:nsswitch) do
  @doc = "Name service switch configuration data. See: nsswitch.conf(5). Values
  shown as absent use the default lookup.

The following database limitations are also applicable:
* default: Sets the default lookup configuration
* sudoer: Used only with sudo
* tnrhtp: Requires trusted extensions
* tnrhdb: Requires trusted extensions
"

  ensurable

  newparam(:name) do
    desc "The symbolic name for the nsswitch settings to use.
          Only the value 'current' is accepted."
    newvalues(:current)
    isnamevar
  end

  [:default, :host, :password, :group, :network, :rpc, :ether,
  :netmask, :bootparam, :publickey, :netgroup, :automount, :alias, :service,
  :project, :auth_attr, :prof_attr, :tnrhtp, :tnrhdb, :sudoer, :ipnodes,
  :protocol, :printer].each { |prop|

  newproperty(prop) do
    desc "The #{prop} database configuration entry"

    # Mostly validate options ignoring any additional criteria
    validate do |value|
      unless prop == :printer
        expr=%r(\b(files|ldap|dns)\b|:\[.*\]|\s)
        expr_spc=%r(\b(files|ldap|dns)\b|:\[.*\])
      else
        expr=%r(\b(files|ldap|dns|user)\b|:\[.*\]|\s)
        expr_spc=%r(\b(files|ldap|dns|user)\b|:\[.*\])
      end
      next if value == 'absent'
      fail "cannot be empty" if value.empty?
      %w(files ldap dns user).each { |word|
        fail "duplicate entry #{word}" if value.scan(word).length > 1
      }
      unless value.gsub(expr,'').empty?
        # return the offending portion without removing interstitial spaces
        fail "Invalid database '" <<
             value.gsub(expr_spc,'').strip << "'"
      end
    end

  end
  }
end
