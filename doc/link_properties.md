
link_properties
===============
Manage Oracle Solaris link properties


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **link** (*namevar*)
    The name of the link

- **properties**
    A hash table of propname=propvalue entries to apply to the link. See
    ipadm(8)

- **temporary**
    Optional parameter that specifies changes to the link are
    temporary.  Changes last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    link_properties
