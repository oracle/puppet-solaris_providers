
vnic
====
Manage the configuration of Oracle Solaris Virtual NICs (VNICs)


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **lower_link**
    The name of the physical datalink over which the VNIC is
operating

- **mac_address**
    Sets the VNIC's MAC address based on  the  specified value.

- **name**
    The name of the VNIC

- **temporary**
    Optional parameter that specifies that  the  VNIC  is  temporary.
    Temporary VNICs last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    vnic
