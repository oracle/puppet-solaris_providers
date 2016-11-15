
evs_properties
==============
Manage global properties of EVS(Elastic Virtual Switch) for both
client and controller. There are two instances associated with
contoller and client properties respectively


Parameters
----------

- **controller**
    SSH address of EVS controller server (client_property)

- **l2_type**
    Define how an EVS will be implemented across machines
    (controller_property)
Valid values are `vlan`, `vxlan`, `flat`, ``. 

- **name**
    Type of properties
    Names are preset to 'controller_property' and 'client_property'

- **uplink_port**
    Specifies the datalink to be used for VLANs or VXLANs
    (controller_property)
    uplink_port value must be in the format of either
    uplink_port=<uplink>  or
    uplink_port='<uplink>;[<vlan-range>];[<vxlan-range>];[<host>];[<flat>]'

- **uri_template**
    URI for per-EVS Node RAD Connection (controller_property)
    The syntax of the uri_template value will be of the form:
    uri_template='ssh://[username@][;<host>]' or
    uri_template='unix://[username@][;<host>]'

- **vlan_range**
    List of VLAN ID ranges that will be used for creating EVS
    (controller_property)
The maximum valid range is 1-4094

- **vxlan_addr**
    IP address on top of which VXLAN datalink should be created
    (controller_property)
    The syntax of the vxlan_addr value will be of the form:
    vxlan_addr=<vxlan_IP_addr>
    orvxlan_addr='<vxlan_IP_addr>;[<vxlan-range>];[<host>]'

- **vxlan_ipvers**
    IP version of the address for VXLAN datalinks (controller_property)

- **vxlan_mgroup**
    Multicast address that needs to be used while creating VXLAN links
    (controller_property)

- **vxlan_range**
    List of VXLAN ID ranges that will be used for creating EVS
    (controller_property)
The maximum valid range is 0-16777215

Providers
---------
    evs_properties
