
boot_environment
================
Manage Oracle Solaris Boot Environments (BEs)


Parameters
----------

- **activate**
    Activate the specified BE
Valid values are `true`, `false`. 

- **clone_be**
    Create a new BE from an existing inactive BE

- **description**
    Description for the new BE

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **name**
    The BE name

- **options**
    Create the datasets for a new BE with specific ZFS
    properties.  Specify options as a hash.

- **zpool**
    Create the new BE in the specified zpool

Providers
---------
    boot_environment
