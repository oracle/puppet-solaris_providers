
ipmp_interface
==============
Manage the configuration of Oracle Solaris IPMP interfaces


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **interfaces**
    An array of interface names to use for the IPMP interface

- **name**
    The name of the IP interface

- **temporary**
    Optional parameter that specifies that the IP interface is
    temporary.  Temporary interfaces last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    ipmp_interface
