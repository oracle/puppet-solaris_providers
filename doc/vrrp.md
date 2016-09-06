
vrrp
====
Manage Solaris Virtual Router Redundancy Protocol (VRRP)
configuration. See vrrpadm(8)
**Note** To use VRRP you must install the vrrp package
system/network/routing/vrrp and enable the vrrp service


Parameters
----------

- **accept**
    The accept mode controls the local  packet
    acceptance  of  the virtual  IP  addresses.
    See vrrpadm(8) for details.
    Default: true

Values can match `/(true|false)/i`.

- **adv_interval**
    The advertisement interval in  milliseconds.  Default  is  1000 (one
    second). The valid interval range is 10-40950.
    Values can match `/^\d+$/`.

- **assoc_ipaddrs**
    The Array of associated virtual  IP  addresses  protected  by  the
    VRRP router in the form.  <ipaddr>[/<prefixlen>]>,
    <hostname>[/<prefixlen>], or 'linklocal'

- **enabled**
    Enable/Disable Router
    true        Router is enabled
    false       Router is disabled
    temp_true   Router is enabled until next reboot
    temp_false  Router is disabled until next reboot
    Values can match `/(?:temp_)?(?:true|false)/i`.

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **interface_name**
    The  interface  on  which  the VRRP router is configured. This
    determines the LAN this VRRP router is running in. For l2  VRRP router, 
    the
    interface can be a physical ethernet interface, a VLAN, or an
    aggregation.
    For l3 VRRP  router,  aside  from  the above  types, the interface can
    also
    be an IPMP interface, or a physical IB interface.
    Values can match `/^[\p{Alnum}_]+$/`.

- **name**
    The name of a VRRP router. This name is used to identify a VRRP
    router in other vrrpadm subcommands.
    The maximum length of a valid router  name  is  31  characters.
    Legal  characters  are  alphanumeric  (a-z,  A-Z,  0-9) and the
    underscore ('_').
Values can match `/^[\p{Alnum}_]+$/`.

- **preempt**
    Flags: The  preempt  mode  controls whether an
    enabled higher priority backup router preempts a lower priority master
    router.
    See vrrpadm(8) for details.
    Default: true

Values can match `/(true|false)/i`.

- **primary_ipaddr**
    The  IP  addresses configured over the <ifname> interface which
    can be potentially selected as the primary IP address  used  to
    send the VRRP advertisement.

- **priority**
    The priority of the specified VRRP router used in master selec-
    tion. The higher the value, the  greater  the  possibility  the
    router is selected as the master.
    The  default  value  is 255, which indicates the specified VRRP
    router is the IP Address Owner and  owns  all  the  virtual  IP
    addresses.
    The range 1-254 is available for VRRP routers backing up a vir-
    tual router.
    See vrrpadm(8) for details.
Default: 255
Values can match `/^\d+/`.

- **router_type**
    VRRP router type. Either l2 or l3.
    Default: L2
Values can match `/l2/i`, `/l3/i`.

- **temporary**
    Specifies  that  the  VRRP  router is temporary. Temporary VRRP
    routers last until the next reboot.
    Default: false
Values can match `/true/i`, `/false/i`.

- **vrid**
    The virtual router identifier (VRID). Together with the address
    family, it identifies a virtual router within a LAN.
    Values can match `/^\d+$/`.

Providers
---------
    vrrp
