
ip_tunnel
=========
Manage the configuration of Oracle Solaris IP Tunnel links


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **local_address**
    IP address or hostname corresponding to the local tunnel address

- **name**
    The name of the iptunnel link

- **remote_address**
    IP address or hostname corresponding to the remote tunnel address

- **temporary**
    Optional parameter that specifies that the IP tunnel is
    temporary.  Temporary IP tunnels last until the next reboot.
    Valid values are `true`, `false`. 

- **tunnel_type**
    Specifies the type of tunnel to be created.
    Valid values are `ipv4`, `ipv6`, `6to4`. 

Providers
---------
    ip_tunnel
