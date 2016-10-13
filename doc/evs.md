
evs
===
Manage the configuration of Oracle Solaris Elastic Virtual Switch
(EVS)


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **l2_type**
    Define how an EVS will be implemented across machines
    Valid values are `vlan`, `vxlan`, `flat`, ``. 

- **maxbw**
    The full duplex bandwidth for the virtual port

- **name**
    The full name for EVS (including the tenant name)

- **priority**
    The relative priority for the virtual port
    Valid values are `high`, `medium`, `low`, ``. 

- **protection**
    Enables one or more types of link protection

- **uuid**
    UUID of the EVS instance

- **vlanid**
    VXLAN segment ID used to implement the EVS

- **vni**
    VLAN ID used to implement the EVS

Providers
---------
    evs
