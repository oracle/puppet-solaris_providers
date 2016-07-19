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

Puppet::Type.newtype(:ilb_healthcheck) do
  @doc = "Manage Solaris Integrated Load Balancer (ILB) health check configuration"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Name for the health check"
  end

  newproperty(:timeout) do
    desc "Threshold at which a test is considered failed
      following interim failures of hc-test. If you kill an hc-test test, the
      result is considered a failure. The default value is five seconds."
      newvalue(/^\d+$/)
  end

  newproperty(:count) do
    desc "Maximum number of attempts to run hc-test before
      marking a server as down. The default value is three iterations."
      newvalue(/^\d+$/)
  end

  newproperty(:interval) do
    desc "Interval between invocations of hc-test. This value must be greater
      than hc-timeout times hc-count. The default value is 30 seconds."
      newvalue(/^\d+$/)
  end

  newproperty(:test) do
    desc "UDP, TCP, external method (script or binary). An external method
      should be specified with a full path name."
      newvalues(:tcp,:udp,%r(^/.+))
  end

  newproperty(:default_ping) do
    desc "Execute default ping test before high layer health check tests.
    Default: true"
    defaultto :true
    newvalues(:true,:false)
  end
end
