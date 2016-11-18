#
# Copyright (c) 2013, 2106, Oracle and/or its affiliates. All rights reserved.
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

# Puppet 4 renames Puppetx to PuppetX
begin
  require 'puppet_x'
rescue LoadError
  # Support Puppet 3.x with the 4.x namespace
  module PuppetX; end
end

module PuppetX::Oracle
  module SolarisProviders
    module Util
    end
  end
end


# Monkey patch String to add svcs_escape
class String
  def svcs_escape
    self.gsub(/([;&()|^<>\n \t\\\"\'`~*\[\]\$\!])/, '\\\\\1')
  end
end
