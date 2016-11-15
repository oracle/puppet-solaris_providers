
ip_interface
============
Manage the configuration of Oracle Solaris IP interfaces


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **name**
    The name of the IP interface

- **temporary**
    Optional parameter that specifies that the IP interface is
    temporary.  Temporary interfaces last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    ip_interface
