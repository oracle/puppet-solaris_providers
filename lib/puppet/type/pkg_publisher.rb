#
# Copyright (c) 2013, 2015, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.newtype(:pkg_publisher) do
  @doc = "Manage Oracle Solaris package publishers.

  If pkg is unable to connect to the publisher after modifications are made
  it will revert the change. e.g. attempts to remove ssl certs and keys
  will fail if the repository cannot be reached after they are removed.

  When setting proxies, sslcerts, and sslkeys the number of each must match
  the combined number of origins and mirrors provided.

  Proxies, certs, and keys are applied to origins and mirrors in the order in
  which they are specified starting with origins.

''''
  pkg_publisher{ 'solaris':
    :enable => 'true',
    :ensure => :present,
    :mirror => [],
    :name => 'solaris',
    :origin => ['file:///media/sol-12_0-119-repo/repo', 'http://pkg.oracle.com/solaris/release'],
    :proxy => [:absent, 'http://bogus.proxy'],
    :searchafter => 'solaris-mirror',
    :searchbefore => nil,
    :searchfirst => nil,
    :sslcert => [:absent, '/cert/for/2nd_origin'],
    :sslkey => nil,
    :sticky => 'true',
  }
''''
  "

  ensurable

  newparam(:name) do
    desc "The publisher name"
    isnamevar
  end

  newproperty(:origin, :array_matching => :all ) do
    desc "Which origin URI(s) to set.  For multiple origins, specify them
              as a list"

    # Stop invalid parameter membership(:membership) errors as we don't have
    # a membership parameter
    def should
      @should
    end

    newvalues(%r([file|http|https]://.*),:absent)

    # for origins with a file:// URI, strip any trailing / character
    munge do |value|
      if value.to_s.end_with? "/"
        value = value.chomp("/")
      else
        value
      end
    end
  end

  newproperty(:enable) do
    desc "Enable the publisher"
    newvalues(:true, :false)
  end

  newproperty(:sticky) do
    desc "Set the publisher 'sticky'"
    newvalues(:true, :false)
  end

  newproperty(:searchfirst) do
    desc "Set the publisher first in the search order"
    newvalues(:true)
  end

  newproperty(:searchafter) do
    desc "Set the publisher after the specified publisher in the search
              order"
  end

  newproperty(:searchbefore) do
    desc "Set the publisher before the specified publisher in the search
              order"
  end

  newproperty(:proxy, :array_matching => :all ) do
    desc "Use the specified web proxy URI to retrieve content for the
              specified origin or mirror (list). If provided the number of
              entries must match the the number of origins and mirrors.
              Provide the value :absent for missing values if no key is needed."
    def should
      @should
    end

    newvalues(%r{^http://},:absent)
  end

  newproperty(:sslkey, :array_matching => :all ) do
    desc "Specify the client SSL key (list). If provided the number of entries
    must match the the number of origins and mirrors. Provide the value :absent
    for missing values if no key is needed."
    def should
      @should
    end
    newvalues(:absent,%r{^/.*})
  end

  newproperty(:sslcert, :array_matching => :all ) do
    desc "Specify the client SSL certificate (list). If provided the number of entries
    must match the the number of origins and mirrors. Provide the value :absent
    for missing values if no key is needed."
    def should
      @should
    end
    newvalues(:absent,%r{^/.*})
  end

  newproperty(:mirror, :array_matching => :all ) do
    desc "Which mirror URI(s) to set.  For multiple mirrors, specify them
              as a list"
    newvalues(%r([file|http|https]://.*),:absent)
    def should
      @should
    end

    munge do |value|
      if value.to_s.end_with? "/"
        value = value.chomp("/")
      else
        value
      end
    end
  end
  validate do
    # Don't try to validate if we don't want the resource to be present
    if self[:ensure] != :present
      return true
    end
    uris = self[:origin].to_a + self[:mirror].to_a
    unless self[:proxy].to_a.empty? ||
           self[:proxy].length == uris.length
      fail("The number of proxies #{self[:proxy].length} must be 0 or equal to the number of origins and mirrors #{uris.length}")
    end
    unless self[:sslcert].to_a.empty? ||
           self[:sslcert].length == uris.length
      fail("The number of sslcerts #{self[:sslcert].length} must be 0 or equal to the number of origins and mirrors #{uris.length}")
    end
    unless self[:sslkey].to_a.empty? ||
           self[:sslkey].length == uris.length
      fail("The number of sslkeys #{self[:sslkey].length} must be 0 or equal to the number of origins and mirrors #{uris.length}")
    end
    true
  end

  # autorequire any sslcert or sslkey
  autorequire(:file) do
    children = catalog.resources.select do |res|
      res.type == :file && (
        (
          !self[:sslcert].nil? &&
          self[:sslcert].include?(res[:path])
        ) || (
          !self[:sslkey].nil? &&
          self[:sslkey].include?(res[:path])
        )
      )
    end
    children.each.collect do |child|
      # We expect name to almost always be the path...almost
      child[:name]
    end
  end

  # autorequire any referenced publisher for search before/after
  autorequire(:pkg_publisher) do
    catalog.resources.select do |res|
      res.type == :pkg_publisher && (
        self[:searchbefore] == res[:name] ||
        self[:searchafter] == res[:name]
      )
    end
  end
end
