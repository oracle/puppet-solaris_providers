
vni_interface
=============
Manage the configuration of Solaris VNI interfaces


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **name**
    The name of the VNI interface

- **temporary**
    Optional parameter that specifies that the VNI interface is
    temporary.  Temporary interfaces last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    vni_interface
