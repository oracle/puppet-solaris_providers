
interface_properties
====================
Manage Oracle Solaris interface properties


Parameters
----------

- **ensure**
    Valid values are `present`. 

- **interface** (*namevar*)
    The name of the interface with protocol (if appropriate)

- **properties**
    A hash table of propname=propvalue entries to apply to the
    interface. See ipadm(8)

- **temporary**
    Optional parameter that specifies changes to the interface are
    temporary.  Changes last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    interface_properties
