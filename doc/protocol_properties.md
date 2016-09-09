
protocol_properties
===================
Manage Oracle Solaris protocol properties


Parameters
----------

- **ensure**
    Valid values are `present`. 

- **properties**
    A hash table of propname=propvalue entries to apply to an
    protocol. See ipadm(8)

- **protocol** (*namevar*)
    The name of the protocol

- **temporary**
    Optional parameter that specifies changes to the protocol are
    temporary.  Changes last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    protocol_properties
