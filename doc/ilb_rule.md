
ilb_rule
========
Manage Solaris Integrated Load Balancer (ILB) rule configuration.
Existing rules cannot be modified they will be removed and re-created


Parameters
----------

- **conn_drain**
    If a server's type is NAT or HALF-TYPE, conn-drain is the timeout
    after which the server's connection state is deleted following the
    server's
    removal from a rule. This deletion occurs even if the server is not
    idle.
    
    The default for TCP is that the connection state remains stable until
    the
    connection is gracefully shutdown. The default for UDP is that the
    connection
    state remains stable until the connection has been idle for the period
    nat-timeout.

Values can match `/^\d+$/`.

- **enabled**
    Indicates if the rule should be enabled or disabled
    Valid values are `true`, `false`. 

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **hc_name**
    Specifies the name of a predefined health check method
    Values can match `/^\p{Alnum}+$/`.

- **hc_port**
    Specifies the port(s) for the HC test program
    to check. The value can be keywords ALL or ANY, or a specific port
    number
    within the port range of the server group.
    Valid values are `all`, `any`. Values can match `/^\d+$/`.

- **lbalg**
    The default is roundrobin, Other alternatives are: hash-ip,
    hash-ip-port, hash-ip-vip
    Valid values are `roundrobin`, `hash_ip`, `hash_ip_port`, `hash_ip_vip`.

- **name**
    Name for the ilb rule

- **nat_timeout**
    Applies only to NAT and half-NAT type connections. If such a
    connection is idle for the nat-timeout period, the connection state will
    be
    removed. The default is 120 for TCP and 60 UDP.
    Values can match `/^\d+$/`.

- **persist_timeout**
    When persistent mapping is enabled, if a numeric-only mapping
    has not been used for persist-timeout seconds, the mapping will be
    removed. The default is 60.
Values can match `/^\d+$/`.

- **persistent**
    Create a persistent rule.
    When provided a pmask value this enables session persistence
    Default: false
    Pmask: The argument is a prefix length in CIDR notation; that is, 0-32
    for IPv4 and 0-128 for IPv6.
    The larger the mask the more of the IP address is used to generate the
    session mapping.
    i.e. An IPv4 address has 32 bits
    
Values can match `/true/i`, `/false/i`, `/\/\d+$/`.

- **port**
    Port number or name, for example, telnet or dns. A port can be
    specified by port number or symbolic name (as in /etc/services).
    Port number ranges are also supported 'port[-port]'.
    ** Note **
    The use of numerical ports is recommended. Service names are not
    validated at compilation time and may fail on individual nodes.

- **protocol**
    TCP (the default) or UDP (see /etc/services).
    Valid values are `tcp`, `udp`. 

- **proxy_src**
    Required for full NAT only. Specifies the IP address range
    to use as the proxy source address range. The range is limited to
    ten IP addresses.

- **servergroup**
    Specifies destination(s) for packets that match the criteria
    specified by the incoming packet spec. Specify a single server group as
    target. The server group must already have been created. Any matching
    ilb_servergroup resource will be auto required
    Values can match `/^[\p{Alnum}_]+$/`.

- **topo_type**
    Refers to topology of network. Can be DSR, NAT, or HALF-NAT
    Valid values are `dsr`, `nat`, `half_nat`. 

- **vip**
    (Virtual) destination IP address

Providers
---------
    ilb_rule
