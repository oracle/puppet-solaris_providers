
evs_vport
=========
Manage the configuration of EVS VPort


Parameters
----------

- **cos**
    802.1p priority on outbound packets on the virtual port

- **ensure**
    Valid values are `present`, `absent`, `reset`. 

- **ipaddr**
    The IP address associated with the virtual port

- **macaddr**
    The MAC address associated with the virtual port

- **maxbw**
    The full duplex bandwidth for the virtual port

- **name**
    The full name of Virtual Port for EVS

- **priority**
    Relative priority of virtual port
    Valid values are `high`, `medium`, `low`, ``. 

- **protection**
    Enables one or more types of link protection

- **uuid**
    UUID of the virtual port

Providers
---------
    evs_vport
