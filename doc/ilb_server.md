
ilb_server
==========
Manage Solaris Integrated Load Balancer (ILB) back end server configuration.
Backend servers can only belong to one server group and are internally
identified as
the combination of server and server group.
** Note **
Creation of server groups without assigned rules will result in catalog
changes for every run as puppet tries to enable the server.


Parameters
----------

- **enabled**
    Should this server be enabled.
    If this server is a member of an unassigned servergroup the value
    will be unassigned.
    **Note:** It it not possible to create a sever in the disabled state.
    Valid values are `true`, `false`, `unassigned`. 

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **name**
    Name for the server, The name of the server definition is arbitrary.
    ** Title Patterns **
    Strings which do not match the pattern will only populate the name
    Specific patterns will be split to auto populate fields
    <servergroup>|<server>
<servergroup>|<server>|<port>


- **port**
    Port is the service name or port number to use for the back end server.
    Port is a service name, port number, or range port-port. If the port
    number is not specified, a number in the range 1-65535 is used.
    **Note:**
    The use of numerical ports is recommended. Service names are not
    validated at compilation time and may fail on individual nodes.

- **server**
    IP of the ILB back end server
    Server is a hostspec in the format hostname or IP address.

- **servergroup**
    Servergroup is the name of the server group this server definition
    belongs to. Servers may be defined in multiple server groups.
    **Autorequires**
    Server group will automatically require any matching ilb_servergroup
    resource.

- **sid**
    System generated ServerID. Value is ignored if manually specified

Providers
---------
    ilb_server
