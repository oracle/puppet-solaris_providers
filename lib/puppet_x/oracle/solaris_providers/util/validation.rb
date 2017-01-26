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

require File.expand_path(File.join(File.dirname(__FILE__), '..','util.rb'))

module PuppetX::Oracle::SolarisProviders::Util::Validation
  def valid_hostname?(hostname)
    # Reject things that bear a strong resembalance to an IPv4 address
    return false if hostname =~ /\A(?:\d{1,3}\.?){4}\Z/
    # Reject overlong names or repeated dot(.)
    return false if hostname.length > 255 or hostname.scan('..').any?
    hostname = hostname[0...-1] if hostname.index('.', -1)
    return hostname.split('.').collect do |i|
      ( i.size <= 63 ) and not (
        i.rindex('-', 0) or
        i.index('-', -1) or
        i.scan(/[^a-z\d-]/i).any?
      )
      end.all?
  end

  def valid_ip?(value)
    begin
      IPAddr.new(value)
    rescue
      return false
    end
    return true
  end

  def valid_ipv4?(value)
    begin
      return false unless IPAddr.new(value).ipv4?
    rescue
      return false
    end
    return true
  end

  def valid_ipv6?(value)
    begin
      return false unless IPAddr.new(value).ipv6?
    rescue
      return false
    end
    return true
  end
end
