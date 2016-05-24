#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright (c) 2013, 2015, 2106, Oracle and/or its affiliates. All rights reserved.
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

class PuppetX::Oracle::SolarisProviders::Util::Validation
  def valid_hostname?(hostname)
    # Reject things that bear a strong resembalance to an IPv4 address
    return false if hostname.match(/\A(?:\d{1,3}\.?){4}\Z/)
    # Reject overlong names or repeated dot(.)
    return false if hostname.length > 255 or hostname.scan('..').any?
    hostname = hostname[0...-1] if hostname.index('.', -1)
    return hostname.split('.').collect { |i|
      ( i.size <= 63 ) and not (
        i.rindex('-', 0) or
        i.index('-', -1) or
        i.scan(/[^a-z\d-]/i).any?
      )
    }.all?
  end

  def valid_ip?(value)
    begin
      IPAddr.new(value)
    rescue
      return false
    end
    return true
  end
end
