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
  @doc = "Manage Solaris Integrated Load Balancer (ILB) health check configuration.
  See: ilbadm(8)

  **Note**
  * Healthchecks cannot be removed/modified while they are assigned to rules
  * Healthchecks cannot be modified only destroyed and recreated
  * Attempts to modify assigned healthchecks will result in catalog run errors
  "

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
      should be specified with a full path name.

      Arguments to external methods
       $1 VIP (literal IPv4 or IPv6 address)
       $2 Server IP (literal IPv4 or IPv6 address)
       $3 Protocol (UDP, TCP as a string)
       $4 Numeric port range (the user-specified value for hc-port)
       $5 Maximum time (in seconds) that the test must wait before returning
          a failure. If the test runs beyond the specified time, it might
          be stopped, and the test is considered failed. This value is
          user-defined and specified in hc-timeout.

      The user-supplied test, my-script, may or may not use all the arguments,
      but it must return one of the following:
       Round-trip time (RTT) in microseconds
       0 if the test does not calculate RTT
       -1 for failure
    "
      newvalues(:tcp,:udp,%r(^/.+))
  end

  newproperty(:default_ping) do
    desc "Execute default ping test before high layer health check tests.
    Default: true"
    defaultto :true
    newvalues(:true,:false)
  end
end
