
evs_ipnet
=========
Manage the configuration of IPnet (subnet of IPv4 or IPv6
addresses)


Parameters
----------

- **defrouter**
    The IP address of the default router for the given IPnet

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **name**
    The full name of IPnet including tenant name

- **pool**
    Sub-ranges of IP addresses within a subnet

- **subnet**
    Subnet (either IPv4 or IPv6) for the IPnet

- **uuid**
    UUID of the IPnet

Providers
---------
    evs_ipnet
