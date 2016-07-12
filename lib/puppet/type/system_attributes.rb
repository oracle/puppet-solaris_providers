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
  @doc = "Manage NFSv4 ACL Specifications and system attributes on ZFS Files. See chmod(1), acl(7)"

  ensurable

  # name/title in the format fully defined fmri will be parsed to automatically
  # populate parameters
  def self.title_patterns
    [
      [ /(\/.*)/m, [ [:file] ] ]
    ]

  end

  newproperty(:name, :namevar => true) do
    desc "The name for the set of ACLs to set on the file.
    Fully qualified paths will be propigated to the file parameter"
  end

  newproperty(:acl) do
    @target = [ "owner@", "group@", "everyone@", :owner, :group, :everyone ]
    @target_patterns = [ /^user:/, /^group:/ ]
    @perms = [
    :read_data, :write_data, :append_data, :read_xattr, :write_xattr,
    :execute, :delete_child, :read_attributes, :write_attributes,
    :delete, :read_acl, :write_acl, :write_owner, :synchronize
    ]
    @perm_sets = [ :full_set, :modify_set, :read_set, :write_set ]
    @inheritance = [ :file_inherit, :dir_inherit, :inherit_only, :no_propagate, :none ]
    @type = [ :allow, :deny, :audit, :alarm ]

    desc <<-HEREDOC
      Access Control List, an ordered array of ACE hashes to set on the
      file. Ordering of the ACL is important.

      Each ACE is defined in the format
      {
        target        => "<target_string>",
        perms         => [<perms_array>],
        inheritance   => [<flags_array>],
        type          => <:allow|:deny|:audit|:alarm>
      }

      Target string: Target string includes the standard owner@, group@,
          and everyone@ as well as the fine grained user:<username> and
          group:<groupname> targets. The usersid:, groupsid:, and sid: targets
          are not supported by this module.

          Attempts to set permissions for non-existent users and groups will fail.

      Perms:
         Individual Permissions:
             :read_data, :write_data, :append_data, :read_xattr, :write_xattr,
             :execute, :delete_child, :read_attributes, :write_attributes,
             :delete, :read_acl, :write_acl, :write_owner, :synchronize

         Special Sets:
             :full_set, :modify_set, :read_set, and :write_set

         :full_set
             All permissions.

         :modify_set
             All permissions except write_acl and write_owner.
             Approximately: rwx

         :read_set
             read_data, read_acl, read_attributes, and read_xattr.
             Approximately: r--

         :write_set
             write_data, append_data, write_attributes, and write_xattr
             Approximately: -w-

      Inheritance: :file_inherit, :dir_inherit, :inherit_only, :no_propagate, :none

      Type: :allow, :deny, :audit, :alarm
          Currently, Solaris does not generate alarms.

      See chmod(1) NFSv4 ACL Specification for additional details

      HEREDOC

      validate { |val|
        val.each { |value|
          fail "value: #{value} must be a hash" unless value.type_of?(Hash)
          fail "target must be defined" unless value[:target]
          fail "perms must be defined" unless value[:perms]
          fail "type must be defined" unless value[:type]

          # Check target value
          unless @target.include(value[:target]) ||
            value[:target].match(Regexp.union(@target_patterns))
            fail "Invalid target: #{value[:target]}"
          end

          # Check Permissions
          bad_perms = []
          value[:perms].each do |thing|
            bad_perms.push(thing) unless @perms.include?(thing)
          end
          fail "Invalid perms: #{bad_perms}" unless bad_perms.empty?

          # Check Inheritance
          bad_inh = []
          value[:inheritance].each do |thing|
            bad_inh.push(thing) unless @inheritance.include?(thing)
          end
          fail "Invalid Inheritance: #{bad_inh}" unless bad_inh.empty?

          # Check type
          fail "Invlid type: #{value[:type]}" unless @type.include?(value[:type])

        }
      }
   end

  newparam(:set_default_perms) do
    desc <<-HEREDOC
      Use the default set of permissions in addition to specified ACEs
      Default: true
      Equavalent to:
       {
         target  => "owner@",
         perms   => [ :read_xattr, :write_xattr, :read_attributes,
                     :write_attributes, :read_acl, :write_acl,
                     :write_owner, :synchronize ],
           type  => :allow
       },
       {
         target  => "group@",
         perms   => [ :read_xattr, :read_attributes, :read_acl, :synchronize ],
         type    =>  :allow
       },
       {
         target  => "everyone@",
         perms   => [ :read_xattr, :read_attributes, :read_acl, :synchronize ],
         type    => :allow
       }
    HEREDOC
    defaultto :true
    newvalues(:true,:false)
  end

  newparam(:purge_acl) do
    desc "Clear all ACEs which are not explicitly defined for this resource.
          Default: true"
    defaultto :true
    newvalues(:true,:false)
  end

  newproperty(:archive) do
    desc "Indicates if a file has been modified since it was last backed up."
    newvalues(/yes/i,/no/i)
  end
  newproperty(:hidden) do
    desc "Marks a file as hidden."
    newvalues(/yes/i,/no/i)
  end
  newproperty(:readonly) do
    desc "Marks a file as readonly."
    newvalues(/yes/i,/no/i)
  end
  newproperty(:system) do
    desc "Solaris systems have no special semantics for this attribute."
    newvalues(/yes/i,/no/i)
  end
  newproperty(:appendonly) do
    desc "Allows a file to be modified only at offset EOF"
    newvalues(/yes/i,/no/i)
  end
  newproperty(:nodump) do
    desc "Solaris systems have no special semantics for this attribute."
    newvalues(/yes/i,/no/i)
  end
  newproperty(:immutable) do
    desc "Prevents the content of a file from being modified.  Also  pre-
          vents  all  metadata  changes,  except for access time updates.
          When placed on a directory, prevents the deletion and  creation
          of  files in the directories."
    newvalues(/yes/i,/no/i)
  end
  newproperty(:av_modified) do
    desc "ZFS  sets the anti-virus attribute which whenever a file's con-
          tent or size changes or when the file is renamed."
    newvalues(/yes/i,/no/i)
  end
  newproperty(:av_quarantined) do
    desc "Anti-virus software sets to mark a file as quarantined."
    newvalues(/yes/i,/no/i)
  end
  newproperty(:nounlink) do
    desc "Prevents  a  file  from  being  deleted.  On  a  directory, the
          attribute also prevents any changes  to  the  contents  of  the
          directory."
    newvalues(/yes/i,/no/i)
  end
  newproperty(:offline) do
    desc "Offline"
    newvalues(/yes/i,/no/i)
  end
  newproperty(:sparse) do
    desc "Sparse"
    newvalues(/yes/i,/no/i)
  end
  newproperty(:sensitive) do
    desc "Some Solaris utilities may take different actions based on this
          attribute. For example, not  recording  the  contents  of  such
          files in administrative logs."
    newvalues(/yes/i,/no/i)
  end

  newparam(:purge_attributes) do
    desc "Clear all System Attributes which are not defined for this resource.
    This may have unexpected results with backup and anti-virus software."
    newvalues(:true,:false)
  end
end
