
link_aggregation
================
Manage the configuration of Oracle Solaris link aggregations


Parameters
----------

- **address**
    Specifies a fixed unicast hardware address to be used for the
    aggregation

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **lacpmode**
    Specifies whether LACP should be used and, if used, the mode
    in which it should operate
Valid values are `off`, `active`, `passive`. 

- **lacptimer**
    Specifies the LACP timer value
Valid values are `short`, `long`. 

- **lower_links**
    Specifies an array of links over which the aggrestion is created.

- **mode**
    Specifies which mode to set.
Valid values are `trunk`, `dlmp`. 

- **name**
    The name of the link aggregration

- **policy**
    Specifies the port selection policy to use for load spreading
    of outbound traffic.

- **temporary**
    Optional parameter that specifies that the aggreation is
    temporary.  Temporary aggregation links last until the next
    reboot.
Valid values are `true`, `false`. 

Providers
---------
    link_aggregation
