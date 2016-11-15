
etherstub
=========
Manage the configuration of Solaris etherstubs


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **name**
    The name of the etherstub

- **temporary**
    Optional parameter that specifies that the etherstub is
    temporary.  Temporary etherstubs last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    etherstub
