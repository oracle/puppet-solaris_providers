
pkg_publisher
=============
Manage Oracle Solaris package publishers


Parameters
----------

- **enable**
    Enable the publisher
Valid values are `true`, `false`. 

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **mirror**
    Which mirror URI(s) to set.  For multiple mirrors, specify them
    as a list

- **name**
    The publisher name

- **origin**
    Which origin URI(s) to set.  For multiple origins, specify them
    as a list

- **proxy**
    Use the specified web proxy URI to retrieve content for the
    specified origin or mirror

- **searchafter**
    Set the publisher after the specified publisher in the search
order

- **searchbefore**
    Set the publisher before the specified publisher in the search
order

- **searchfirst**
    Set the publisher first in the search order
Valid values are `true`. 

- **sslcert**
    Specify the client SSL certificate

- **sslkey**
    Specify the client SSL key

- **sticky**
    Set the publisher 'sticky'
Valid values are `true`, `false`. 

Providers
---------
    pkg_publisher
