
dns
===
Manage the configuration of the DNS client for Oracle Solaris


Parameters
----------

- **domain**
    The local domain name

- **name**
    The symbolic name for the DNS client settings to use.  This name
    is used for human reference only.

- **nameserver**
    The IP address(es) the resolver is to query.  A maximum of
    3 IP addresses may be specified.  Specify multiple IP addresses
    as an array

- **options**
    Set internal resolver variables.  Valid values are debug,
    ndots:n, timeout:n, retrans:n, attempts:n, retry:n, rotate,
    no-check-names, inet6.  For values with 'n', specify 'n' as an
    integer.  Specify multiple options as an array.

- **search**
    The search list for host name lookup.  A maximum of 6 search
    entries may be specified.  Specify multiple search entries as an
array.

- **sortlist**
    Addresses returned by gethostbyname() to be sorted.  Entries must
    be specified in IP 'slash notation'.  A maximum of 10 sortlist
    entries may be specified.  Specify multiple entries as an array.

Providers
---------
    dns
