
address_object
==============
Manage the configuration of Oracle Solaris address objects


Parameters
----------

- **address**
    A literal IP address or a hostname corresponding to the local
    end-point.  An optional prefix length may be specified.  Only
    valid with an address_type of 'static'

- **address_type**
    The type of address object to create.  Valid values are static,
    dhcp, addrconf.
    Valid values are `static`, `dhcp`, `addrconf`, `from_gz`, `inherited`. 

- **down**
    Specifies that the configured address should be marked down.
    Only valid with an address_type of 'static'.
    Valid values are `true`, `false`. 

- **enable**
    Specifies the address object should be enabled or disabled.
    This property is only applied temporarily, until next reboot.
    Valid values are `true`, `false`. 

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **hostname**
    Specifies the hostname to which the client would like the DHCP
    server to map the client's leased IPv4 address.  Only valid
    with an address_type of 'dhcp'

- **interface_id**
    Specifies the local interface ID to be used for generating
    auto-configured addresses.  Only valid with an address_type of
    'addrconf'
Values can match `/\A\p{Alnum}+\/v[46](?:\p{Alpha}{0,})?\Z/`.

- **name**
    The name of the address object or interface

- **remote_address**
    A literal IP address or a hostname corresponding to an optional
    remote end-point.  An optional prefix length may be specified.
    Only valid with an address_type of 'static'

- **remote_interface_id**
    Specifies an optional remote interface ID to be used for
    generating auto-configured addresses.  Only valid with an
    address_type of 'addrconf'
    Values can match `/\A\p{Alnum}+\/v[46](?:\p{Alpha}{0,})?\Z/`.

- **seconds**
    Specifies the amount of time in seconds to wait until the
    operation completes.  Only valid with an address_type of
    'dhcp'.  Valid values are a numerical value in seconds or
    'forever'
Valid values are `forever`. Values can match `/\d+/`.

- **stateful**
    Specifies if stateful auto-configuration should be enabled or
    not.
Valid values are `yes`, `no`. 

- **stateless**
    Specifies if stateless auto-configuration should be enabled or
    not.
Valid values are `yes`, `no`. 

- **temporary**
    Optional parameter that specifies that the address object is
    temporary.  Temporary address objects last until the next reboot.
    Valid values are `true`, `false`. 

Providers
---------
    address_object
