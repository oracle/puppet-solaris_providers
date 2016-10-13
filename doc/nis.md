
nis
===
Manage the configuration of the NIS client for Oracle Solaris


Parameters
----------

- **domainname**
    The NIS domainname

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **name**
    The symbolic name for the NIS domain and client settings to use.
    This name is used for human reference only.

- **securenets**
    Entries for /var/yp/securenets.  Each entry must be a hash.
    The first element in the hash is either a host or a netmask.
    The second element must be an IP network address.  Specify
    multiple entries as separate entries in the hash.

- **use_broadcast**
    Send a broadcast datagram requesting needed bind information for
    a specific NIS server.
Valid values are `true`, `false`. 

- **use_ypsetme**
    Only allow root on the client to change the binding to a desired
    server.
Valid values are `true`, `false`. 

- **ypservers**
    The hosts or IP addresses to use as NIS servers.  Specify
    multiple entries as an array

Providers
---------
    nis
