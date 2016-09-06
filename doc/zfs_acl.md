
zfs_acl
=======
Manage NFSv4 ACL Specifications on ZFS Files.
  See chmod(1), acl(7)
Simple examples:
 This is a contrived example to show setting permissions equavalent to 755
   it could be more easily acomplished via the File provider. Once any acl
   customization is required all permissions must be managed via this
provider.


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


Parameters
----------

- **acl**
    Access Control List, an ordered array of ACE hashes to set on the
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
    
     Attempts to set permissions for non-existent users and groups will
    fail.
    
    Perms:
    Individual Permissions:
        'read_data', 'write_data', 'append_data', 'read_xattr',
    'write_xattr',
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
    
    Inheritance: 'file_inherit', 'dir_inherit', 'inherit_only',
    'no_propagate', 'absent'
    
    Perm Type: 'allow', 'deny', 'audit', 'alarm'
     Currently, Solaris does not generate alarms.
    
See chmod(1) NFSv4 ACL Specification for additional details


- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **file**
    Fully specified path to the file to be managed
    Values can match `/^\/.*/`.

- **name**
    The name for the set of ACLs to set on the file.
    Fully qualified paths will be propagated to the file parameter

- **purge_acl**
    Clear all ACEs which are not explicitly defined for this resource.
    This is the only implemented behavior
Valid values are `true`. 

- **set_default_perms**
    Use the default set of permissions in addition to specified ACEs,
    where applicable directory permissions are automatically granted
    from the listed set.
    
    **Note** Only explicitly defined permissions will be shown in change
    output.
    
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
           perms     => [ 'read_xattr', 'read_attributes', 'read_acl',
    'synchronize' ]',
           perm_type =>  'allow'
         },
         {
           target     => 'everyone@',
           perms      => [ 'read_xattr', 'read_attributes', 'read_acl',
    'synchronize' ]',
           perm_type  => 'allow'
         }
```

Valid values are `true`, `false`. 

Providers
---------
    zfs_acl
