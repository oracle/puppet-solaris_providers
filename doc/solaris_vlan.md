
solaris_vlan
============
Manage the configuration of Oracle Solaris VLAN links


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **force**
    Optional parameter to force the creation of the VLAN link
    Valid values are `true`, `false`. 

- **lower_link**
    Specifies Ethernet link over which VLAN is created

- **name**
    The name of the VLAN

- **temporary**
    Optional parameter that specifies that the VLAN is
    temporary.  Temporary VLAN links last until the next reboot.
    Valid values are `true`, `false`. 

- **vlanid**
    VLAN link ID

Providers
---------
    solaris_vlan
