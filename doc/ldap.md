
ldap
====
Manage the configuration of the LDAP client for Oracle Solaris


Parameters
----------

- **admin_bind_dn**
    The Bind Distinguished Name for the administrator identity that
    is used for shadow information update

- **admin_bind_passwd**
    The administrator password

- **attribute_map**
    A mapping from an attribute defined by a service to an attribute
    in an alternative schema.  Specify multiple mappings as an array.

- **authentication_method**
    The default authentication method(s).  Specify multiple methods
    as an array.
    Valid values are `none`, `simple`, `sasl/CRAM-MD5`, `sasl/DIGEST-MD5`,
    `sasl/GSSAPI`, `tls:simple`, `tls:sasl/CRAM-MD5`, `tls:sasl/DIGEST-MD5`.

- **bind_dn**
    An entry that has read permission for the requested database.
    Specify multiple entries as an array.

- **bind_passwd**
    password to be used for authenticating the bind DN.

- **bind_time_limit**
    The maximum number of seconds a client should spend performing a
    bind operation.

- **credential_level**
    The credential level the client should use to contact the
    directory.
Valid values are `anonymous`, `proxy`, `self`. 

- **enable_shadow_update**
    Specify whether the client is allowed to update shadow
    information.
Valid values are `true`, `false`. 

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **follow_referrals**
    The referral setting.
Valid values are `true`, `false`. 

- **host_certpath**
    The location of the certificate files

- **name**
    The symbolic name for the LDAP client settings to use.  This name
    is used for human reference only.

- **objectclass_map**
    A  mapping from an objectclass defined by a service to an
    objectclass in an alternative schema.  Specify multiple mappings
    as an array.

- **preferred_server_list**
    LDAP server(s) to contact before any servers listed in
    default_server_list

- **profile**
    The LDAP profile name

- **profile_ttl**
    The TTL value in seconds for the client information

- **search_base**
    The default search base DN

- **search_scope**
    The default search scope for the client's search operations.
    Valid values are `base`, `one`, `sub`. 

- **search_time_limit**
    The maximum number of seconds allowed for an LDAP search
operation.

- **server_list**
    LDAP server names or addresses.  Specify multiple servers as an
array

- **service_authentication_method**
    The authentication method to be used by a service.  Specify
    multiple methods as an array.

- **service_credential_level**
    The credential level to be used by a service.
    Valid values are `anonymous`, `proxy`. 

- **service_search_descriptor**
    How and where LDAP should search for information for a particular
    service

Providers
---------
    ldap
