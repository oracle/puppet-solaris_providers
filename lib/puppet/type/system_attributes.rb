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

Puppet::Type.newtype(:system_attributes) do
  @doc = "Manage system attributes on ZFS files. See chmod(1)
  Autorequires the referenced file if it is managed by Puppet."

  ensurable

  def self.title_patterns
    [
      [ /((\/.*))/m, [ [:name],[:file] ] ],
      [ /(.*)/m, [ [:name] ] ]
    ]

  end

  newparam(:name, :namevar => true) do
    desc "The name for the set of attributes to set on the file.
    Fully qualified paths will be propagated to the file parameter"
  end

  newparam(:file) do
    desc "The fully specified path of the file"
    newvalues(%r(^/.+))
  end

  newproperty(:archive) do
    desc "Indicates if a file has been modified since it was last backed up.
    Archive is set whenever the mtime of the file is changed"
    newvalues(/yes/i,/no/i)

    def insync?(is)
      debug "#{should} == #{is}"
      if @resource[:ignore_archive] == 'true'
        debug "Ignoring difference in archive"
        return true if should == :absent
      end
      # fallback to default behavior
      super
    end
  end

  newparam(:ignore_archive) do
    desc "Ignore archive flag settings on file if they are not set in the resource.
    Default: true"
    defaultto 'true'
    newvalues(/true/i,/false/i)
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
    def insync?(is)
      if @resource[:ignore_av_modified] == 'true'
        debug "Ignoring difference in av_modified"
        return true if should == :absent
      end
      # fallback to default behavior
      super
    end
  end

  newparam(:ignore_av_modified) do
    desc "Ignore av_modified flag settings on file if they are not set in the resource.
    Default: true"
    defaultto "true"
    newvalues(/true/i,/false/i)
  end

  newproperty(:av_quarantined) do
    desc "Anti-virus software sets to mark a file as quarantined."
    newvalues(/yes/i,/no/i)
    def insync?(is)
      if @resource[:ignore_av_modified] == 'true'
        debug "Ignoring difference in av_quarantined"
        return true if should == :absent
      end
      # fallback to default behavior
      super
    end
  end

  newparam(:ignore_av_quarantined) do
    desc "Ignore av_quarantined flag settings on file if they are not set in the resource.
    Default: true"
    defaultto "true"
    newvalues(/true/i,/false/i)
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

  newparam(:strict) do
    desc "Set only the attributes explicitly defined in the resource clearing
    all other attributes.

    Strict changes are only applied if other attributes are changed.
    Strict respects ignore_* parameters.
    Default: false
    "
    defaultto 'false'
    newvalues(/true/i,/false/i)
  end

  autorequire(:file) do
    # Expand path may not be required here.
    # We are already expecting file to be absolute
    [File.expand_path(self[:file]).to_s]
  end
end
