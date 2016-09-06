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


Puppet::Type.newtype(:zfs_acl) do
  require Pathname.new(__FILE__).dirname + '../../' + 'puppet/type/zfs_acl/ace'
  @doc = "
  Manage NFSv4 ACL Specifications on ZFS Files.
  See chmod(1), acl(7)

  Simple examples:

   This is a contrived example to show setting permissions equavalent to 755
   it could be more easily acomplished via the File provider. Once any acl
   customization is required all permissions must be managed via this provider.


```ruby
    zfs_acl { '/root/foo':
      ensure => 'present',
      acl    => [
        {
         'target' => 'owner@',
         'perm_type' => 'allow',
         'perms' => ['read_data', 'write_data', 'append_data', 'execute'],
        },
        {
         'target' => 'group@',
         'perm_type' => 'allow',
         'perms' => ['read_data', 'execute'],
        },
        {
         'target' => 'everyone@',
         'perm_type' => 'allow',
         'perms' => ['read_data', 'execute'],
        },
     ],
    }
```

  The following example sets permissions equavalent to 755 and also grants
  the full set of permissions to user jack but removes the write_acl
  permission. The *_set permissions are expended internally and applied
  individually.


```ruby
    zfs_acl { '/root/foo':
      ensure => 'present',
      acl    => [
        {
          'target' => 'user:jack',
          'perm_type' => 'deny',
          'perms' => 'write_acl',
        },
        {
          'target' => 'user:jack',
          'perm_type' => 'allow',
          'perms' => 'full_set',
        },
        {
         'target' => 'owner@',
         'perm_type' => 'allow',
         'perms' => ['read_data', 'write_data', 'append_data', 'execute'],
        },
        {
         'target' => 'group@',
         'perm_type' => 'allow',
         'perms' => ['read_data', 'execute'],
        },
        {
         'target' => 'everyone@',
         'perm_type' => 'allow',
         'perms' => ['read_data', 'execute'],
        },
     ],
    }
```


  **Autorequires:** If Puppet is managing the file of a zfs_acl resource or
  the user or group of an ACE, the zfs_acl type will autorequire them.

  **Note:** Use of the File provider to manage permissions in addition to this
  type may result in changes being applied at every catalog application.
  "

  ensurable

  # name/title in the format fully defined fmri will be parsed to automatically
  # populate parameters
  def self.title_patterns
    [
      [ /((\/.*))/m, [ [:file],[:name] ] ],
      [ /(.*)/m, [ [:name] ] ]
    ]
  end

  newparam(:name) do
    isnamevar
    desc "The name for the set of ACLs to set on the file.
    Fully qualified paths will be propagated to the file parameter"
  end

  newproperty(:file) do
    desc "Fully specified path to the file to be managed"
    newvalues(/^\/.*/)
  end

  newproperty(:acl, :array_matching => :all) do
    def initialize(args)
      super(args)
      @ace_valid = Puppet::Type::ZfsAcl::Ace::Util
    end

    def insync?(current)
      # We need to add default perms to @should to keep
      # insync? working as expected
      if provider.set_default_perms
        @should = provider.add_default_perms(should)
      end

      return false unless current.length == should.length

      # Map to_s to flatten differences between directory and file
      # permission sets. Order matters so we can't just compare hashes
      (0..current.length).each { |idx|
        return false unless current[idx].to_s == should[idx].to_s
      }
      return true
    end

    desc "Access Control List, an ordered array of ACE hashes to set on the
 file. Ordering of the ACL is important.  The 0th ACL entry will be first
 in the array.

Each ACE is defined in the format

```ruby
      {
        target        => '<target_string>',
        perms         => [<perms_array>],
        inheritance   => [<flags_array>],
        perm_type     => <'allow'|'deny'|'audit'|'alarm'>
      }
```

Target: Target string includes the standard owner@, group@,
  and everyone@ as well as the fine grained user:<username> and
  group:<groupname> targets. The usersid:, groupsid:, and sid: targets
  are not supported by this module.

  Attempts to set permissions for non-existent users and groups will fail.

Perms:
 Individual Permissions:
     'read_data', 'write_data', 'append_data', 'read_xattr', 'write_xattr',
     'execute', 'delete_child', 'read_attributes', 'write_attributes',
     'delete', 'read_acl', 'write_acl', 'write_owner', 'synchronize'

 Directory Permissions:
     'list_directory', 'add_subdirectory', 'add_file'

 Special Sets:
     'full_set', 'modify_set', 'read_set', and 'write_set'
     **Note:** Sets are provided for compatiblity, permissions are
     managed and reported individually.

 'full_set'
     All permissions.

 'modify_set'
     All permissions except write_acl and write_owner.
     Approximately: rwx

 'read_set'
     read_data, read_acl, read_attributes, and read_xattr.
     Approximately: r--

 'write_set'
     write_data, append_data, write_attributes, and write_xattr
     Approximately: -w-

Inheritance: 'file_inherit', 'dir_inherit', 'inherit_only', 'no_propagate', 'absent'

Perm Type: 'allow', 'deny', 'audit', 'alarm'
  Currently, Solaris does not generate alarms.

See chmod(1) NFSv4 ACL Specification for additional details
"

    munge { |value|
      Puppet::Type::ZfsAcl::Ace.new(value,self)
    }


    # output similar to ls -v output as ACE hashes is unreadable
    def is_to_s(value)
      value.each_with_index.collect { |val,idx| [idx,val.to_s].join(':') }
    end
    def should_to_s(value)
      value.each_with_index.collect { |val,idx| [idx,val.to_s].join(':') }
    end

    validate { |value|
      fail "value: #{val}:#{val.class} must be a hash" unless value.kind_of?(Hash)
      # Keys needs to be munged back into strings if they came from
      # the provider adding new ACEs
      value.dup.each_pair {|k,v|
        next if k.kind_of?(String)
        value.delete(k)
        value[k.to_s] = v
      }
      fail "#{value} target must be defined" unless value['target']
      fail "perms must be defined" unless value['perms']
      fail "perm_type must be defined" unless value['perm_type']

      # Check target value
      unless @ace_valid.target.include?(value['target']) ||
        value['target'].match(Regexp.union(@ace_valid.target_patterns))
        fail "Invalid target: #{value['target']}"
      end

      # Check Permissions
      bad_perms = []
      bad_perms = bad_perms + ([value['perms']].flatten.compact -
                               @ace_valid.all_perms)
      fail "Invalid perms: #{bad_perms}" unless bad_perms.empty?

      # Check Inheritance
      bad_inh = []
      [value['inheritance']].flatten.compact.each do |thing|
        bad_inh = bad_inh + (value['inheritance'] - @ace_valid.inheritance)
      end
      fail "Invalid Inheritance: #{bad_inh}" unless bad_inh.empty?

      # Check perm_type
      unless @ace_valid.perm_type.include?(value['perm_type'])
        fail "Invalid perm_type: #{value['perm_type']}"
      end
    }
  end

  newparam(:set_default_perms) do
    desc "Use the default set of permissions in addition to specified ACEs,
  where applicable directory permissions are automatically granted
  from the listed set.

**Note** Only explicitly defined permissions will be shown in change output.

Default: true

Equavalent to:

```ruby
       {
         target      => 'owner@',
         perms       => [ 'read_xattr', 'write_xattr', 'read_attributes',
                          'write_attributes', 'read_acl', 'write_acl',
                          'write_owner', 'synchronize' ]',
         perm_type  => 'allow'
       },
       {
         target    => 'group@',
         perms     => [ 'read_xattr', 'read_attributes', 'read_acl', 'synchronize' ]',
         perm_type =>  'allow'
       },
       {
         target     => 'everyone@',
         perms      => [ 'read_xattr', 'read_attributes', 'read_acl', 'synchronize' ]',
         perm_type  => 'allow'
       }
```
"
    defaultto :true
    newvalues(:true,:false)
    munge { |value|
      return value if [TrueClass,FalseClass].include?(value.class)
      value == :true || value == 'true'  ? true : false
    }
  end

  newparam(:purge_acl) do
    desc "Clear all ACEs which are not explicitly defined for this resource.
    This is the only implemented behavior"
    defaultto 'true'
    newvalues('true')
  end

  autorequire(:file) do
    # Expand path may not be required here.
    # We are already expecting file to be absolute
    [File.expand_path(self[:file]).to_s]
  end

  autorequire(:user) do
    self[:acl].each_with_object([]) do |ace,arr|
      next unless ace.target.match(/^user:(.*)/)
      arr.push($1)
    end
  end

  autorequire('group') do
    self[:acl].each_with_object([]) do |ace,arr|
      next unless ace.target.match(/^group:(.*)/)
      arr.push($1)
    end
  end

end
