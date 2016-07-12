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

Puppet::Type.type(:zfs_acl).provide(:zfs_acl) do
  desc "Provider for management of ZFS ACLs for Oracle Solaris"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :chmod => '/usr/bin/chmod', :ls => '/usr/bin/ls'

  mk_resource_methods

  def self.initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.default_perms
    {
      :owner => [ :read_xattr, :write_xattr, :read_attributes,
        :write_attributes, :read_acl, :write_acl,
        :write_owner, :synchronize ],
      :group => [ :read_xattr, :read_attributes, :read_acl, :synchronize ],
      :everyone => [ :read_xattr, :read_attributes, :read_acl,
          :synchronize ],
    }
  end

  def join_ace(ace)

    # All fields even can be provided even if perms or inheritance
    # are empty
    _str = "%s:%s:%s:%s" % [
      ace[:target],
      ace[:perms].index(:absent) ? "" :  ace[:perms] * "/",
      ( ace[:inheritance].index(:absent) ? "" :  ace[:inheritance] * "/" rescue "" ),
      ace[:perm_type]
    ]
  end

  def split_ace(ace)
    # The number of fields from split in the output is variable
    # from 3 - 5
    # target:perms:[inheritance:]perm_type

    hsh = { :target => "",
        :perms => [],
        :inheritance => [],
        :perm_type => "" }

    fields = ace.split(":")

    # The last field is always the type
    hsh[:perm_type] = fields.pop.intern

    # The first one or two fields define the target
    if %w(user group groupsid usersid sid).include?(fields[0])
      hsh[:target] = fields.slice!(0,2).join(":")
    else
      hsh[:target] = fields.shift
    end

    # The next field is perms even if it is empty
    hsh[:perms] = fields.shift.split("/").map!{ |perm| perm.intern }
    # It does appear possible to define an ACE with only inheritance
    # I'm not sure that has any practical application
    hsh[:perms].push(:absent) if hsh[:perms].empty?

    # If there is a field here it is inheritance
    unless fields.empty?
      hsh[:inheritance] = fields.shift.split("/").map!{ |inh| inh.intern }
    else
      hsh[:inheritance].push(:absent)
    end

    # There should never be any fields left over
    fail "Did not process all ACE fields: #{fields}" unless fields.empty?

    hsh
  end

  # Scan the owner@, group@, and everyone@ entries to see if they
  # contain the default set of perms exclusive of read/write/execute
  def has_default_perms?
    owner = self.class.default_perms[:owner].dup
    group = self.class.default_perms[:group].dup
    everyone = self.class.default_perms[:everyone].dup

    # Walk each ACE reduce the set of defaults for each
    # perms array with matches in discovered set
    acl.each { |ace|
      case ace[:target]
      when "owner@"
        owner = owner - ace[:perms]
      when "group@"
        group = group - ace[:perms]
      when "everyone@"
        everyone = everyone - ace[:perms]
      end
    }

   # If the set is empty all default perms are
   # currently set
   (owner + group + everyone).empty?
  end

  def add_default_perms
    return if has_default_perms?
    owner_found = false
    group_found = false
    everyone_found = false

    # Add the default permission set to the first acl entry for owner, everyone and group
    _acl = @resource[:acl].dup
    _acl.each { |ace|
      case ace[:target]
      when "owner@"
        owner_found = true
        ace[:perms] = (ace[:perms] + self.class.default_perms[:owner]).uniq
      when "group@"
        group_found = true
        ace[:perms] = (ace[:perms] + self.class.default_perms[:group]).uniq
      when "everyone@"
        everyone_found = true
        ace[:perms] = (ace[:perms] + self.class.default_perms[:everyone]).uniq
      end
    }

    # Order here is also important or it will never match the default
    unless owner_found
    _acl.push({ :target => :owner,
      :perms => self.class.default_perms[:owner], :perm_type => :allow })
    end

    unless group_found
    _acl.push({ :target => :group,
      :perms => self.class.default_perms[:group], :perm_type => :allow })
    end

    unless everyone_found
    _acl.push({ :target => :everyone,
      :perms => self.class.default_perms[:everyone], :perm_type => :allow })
    end

    # Replace ACL with our updated copy
    @resource[:acl] = _acl

    nil
  end

  def has_custom_perms?
    # Check if a file has anything other than read_data, write_data,
    # or execute permissions in addition to the custom set

    # Walk each ACE reduce the set of defaults for each
    # perms array with matches in discovered set
    acl.each { |ace|
      perms = ace[:perms].dup - [:read_data, :write_data, :execute]

      case ace[:target]
      when /:/
        # Any target with : is custom return true
        # immediately
        return true
      when "owner@"
        # Owner additionally gets append_data in the default set
       perms = perms - (self.class.default_perms[:owner] + [:append_data])
      when "group@"
       perms = perms - self.class.default_perms[:group]
      when "everyone@"
       perms = perms - self.class.default_perms[:everyone]
      end

      # Stop at the first ACE with custom permissions
      return true if not perms.empty?
    }
    return false
  end

  def exists?
    # return true immediately if we have already set :ensure
    return true if @property_hash[:ensure] == :present

    # Because we don't actually implement instances
    # populate the property_hash here
    @property_hash[:acl] = acl
    @property_hash[:ensure] = :present
    @property_hash[:file] = @resource[:file]
    @property_hash[:set_default_perms] = has_default_perms?
    return true
  rescue Puppet::ExecutionFailure
    @property_hash[:ensure] = :absent
    return false
  end

  def self.instances
    # We don't attempt to fetch all files to read their ACLs
    # but we need to define instances for puppet resource
    []
  end

  def insync?
    return false if @resource[:set_default_perms] == :true && !has_default_perms?
    super
  end

  def acl
    return @property_hash[:acl] if @property_hash[:acl]
    line_expr = %r(^\d+:|^/|^:)

    entries = ls("-v", @resource[:file]).
      each_line.
      each_with_object([]) do |line,arr|
      line.strip!
      # Skip the first line of output
      next unless lmatch = line.match(line_expr)

      # lines which begin with a number are the start of an ACE
      if $&.match(/^\d+:/)
        arr.push("")
        arr[-1] = lmatch.post_match
      else
        arr[-1] << line
      end
      end

    # When applied these entries must be reversed so the last
    # entry is first
    entries.each_with_object(@property_hash[:acl]=[]) do |ace,arr|
      arr.push(split_ace(ace))
    end
  end

  def acl=(value)
    args=[@resource[:file]]

    # When applied ACL entries must be reversed so the last
    # entry is applied first. ACEs are applied as a comma
    # separated list
    if @resource[:purge_acl]
      str="A="
      str << value.reverse.map { |ace| join_ace(ace) }.join(",")
      args.unshift str
    end

    chmod(*args)

    # Refresh the ACL if a change was made
    @property_hash.delete(:acl) && acl
  end

  def merge_acl

  end

  def create
    if @resource[:set_default_perms] == :true
      add_default_perms
    end

      self.acl= @resource[:acl]
      return nil
  end

  def destroy
    binding.pry
    # Removes all fine grained ACEs from the resource replacing them with
    # the set of ACEs which represent the current mode of the file and the
    # default set. e.g. leaves read, write, execute removes everything else
    chmod("A-", @resource[:file]) if has_custom_perms?
  end
end
