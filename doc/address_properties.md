
address_properties
==================
Manage Oracle Solaris address properties


Parameters
----------

- **address** (*namevar*)
    The name of the address object

- **ensure**
    Valid values are `present`. 

- **properties**
    A hash table of propname=propvalue entries to apply to an
    address object. See ipadm(8)

- **temporary**
    Optional parameter that specifies changes to the address object
    are temporary.  Changes last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    address_properties
