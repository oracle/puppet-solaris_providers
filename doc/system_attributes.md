
system_attributes
=================
Manage system attributes on ZFS files. See chmod(1)
Autorequires the referenced file if it is managed by Puppet.
**Note** Default behavior affects only the explicitly defined
attributes. See the 'strict' and 'ignore_*' parameters to change
default behaviors.


Parameters
----------

- **appendonly**
    Allows a file to be modified only at offset EOF
    Values can match `/yes/i`, `/no/i`.

- **archive**
    Indicates if a file has been modified since it was last backed up.
    Archive is set whenever the mtime of the file is changed
    Values can match `/yes/i`, `/no/i`.

- **av_modified**
    ZFS  sets the anti-virus attribute which whenever a file's con-
    tent or size changes or when the file is renamed.
    Values can match `/yes/i`, `/no/i`.

- **av_quarantined**
    Anti-virus software sets to mark a file as quarantined.
    Values can match `/yes/i`, `/no/i`.

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **file**
    The fully specified path of the file
Values can match `/^\/.+/`.

- **hidden**
    Marks a file as hidden.
Values can match `/yes/i`, `/no/i`.

- **ignore_archive**
    Ignore archive flag settings on file if they are not set in the
    resource.
Default: true
Values can match `/true/i`, `/false/i`.

- **ignore_av_modified**
    Ignore av_modified flag settings on file if they are not set in the
    resource.
Default: true
Values can match `/true/i`, `/false/i`.

- **ignore_av_quarantined**
    Ignore av_quarantined flag settings on file if they are not set in the
    resource.
Default: true
Values can match `/true/i`, `/false/i`.

- **immutable**
    Prevents the content of a file from being modified.  Also  pre-
    vents  all  metadata  changes,  except for access time updates.
    When placed on a directory, prevents the deletion and  creation
    of  files in the directories.
Values can match `/yes/i`, `/no/i`.

- **name**
    The name for the set of attributes to set on the file.
    Fully qualified paths will be propagated to the file parameter

- **nodump**
    Solaris systems have no special semantics for this attribute.
    Values can match `/yes/i`, `/no/i`.

- **nounlink**
    Prevents  a  file  from  being  deleted.  On  a  directory, the
    attribute also prevents any changes  to  the  contents  of  the
    directory.
Values can match `/yes/i`, `/no/i`.

- **offline**
    Offline
Values can match `/yes/i`, `/no/i`.

- **readonly**
    Marks a file as readonly.
Values can match `/yes/i`, `/no/i`.

- **sensitive**
    Some Solaris utilities may take different actions based on this
    attribute. For example, not  recording  the  contents  of  such
    files in administrative logs.
Values can match `/yes/i`, `/no/i`.

- **sparse**
    Sparse
Values can match `/yes/i`, `/no/i`.

- **strict**
    Set only the attributes explicitly defined in the resource clearing
    all other attributes.
    Strict changes are only applied if other attributes are changed.
    Strict respects ignore_* parameters.
    Default: false
Values can match `/true/i`, `/false/i`.

- **system**
    Solaris systems have no special semantics for this attribute.
    Values can match `/yes/i`, `/no/i`.

Providers
---------
    system_attributes
