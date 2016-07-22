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

Puppet::Type.newtype(:ilb_servergroup) do
  @doc = "Manage Solaris Integrated Load Balancer (ILB) servergroup definition."
  ensurable

  newparam(:name, :namevar => true) do
    desc "Name for the server group. Name automatically populates servergroup"
  end

  newproperty(:servergroup) do
    desc <<-HEREDOC
    Name of the servergroup

    ** Note **
    * Attempts to remove a server group associated with an existing rule will fail.
    HEREDOC

    validate do |value|
      return false unless value.match(/^\p{Alnum}+$/)
    end
  end
end
