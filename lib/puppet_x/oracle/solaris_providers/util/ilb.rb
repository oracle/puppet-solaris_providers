#
# Copyright (c) 2106, Oracle and/or its affiliates. All rights reserved.
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

require 'ipaddr'
module PuppetX::Oracle
  module SolarisProviders
    module Util
    end
  end
end

# ILB has a flexible defintion of ports
# these methods will return puppet failures
# instead of true false as in validation.rb
class PuppetX::Oracle::SolarisProviders::Util::Ilb
  def self.valid_portspec?(value)
    if value.match(/\d+-\d+/)
      # Check port ranges
      value.split('-').each { |prt|
        unless prt.match(/^\d+$/)
          fail "Invalid port spec #{value} -> #{prt}"
        end
        unless (1...65535).include?(prt.to_i)
          fail "Invalid port #{prt} out of range 1-65535"
        end
      }
    elsif value.match(/^\d+$/)
      # Check purely numeric ports
      unless (1...65535).include?(value.to_i)
        fail "Invalid port #{value} out of range 1-65535"
      end
    elsif !value.match(/^\p{Alnum}+$/)
      # Sort of check string options
      fail "Invalid port #{value} is not numeric or alpha numeric"
    end
  end
end
