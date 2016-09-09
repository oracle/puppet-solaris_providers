# solaris\_providers

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with solaris\_providers](#setup)

  * [What solaris\_providers affects](#what-solaris_providers-affects)
  * [Beginning with solaris\_providers](#beginning-with-solaris_providers)

4. [Usage - Configuration options and additional functionality](#usage)

5. [Limitations - OS compatibility, etc.](#limitations)

6. [Development - Guide for contributing to the module](#development)


## Overview

The Oracle Solaris Providers module includes Solaris-specific implementations of
types and providers. These include some common features as well as features
found exclusively on Oracle Solaris.

## Module Resource Type Reference

The Oracle Solaris Providers module currently enables configuration of the
following:

* Boot Environments via beadm

  * [boot\_environment](doc/boot_environment.md)

* Naming Services via svccfg, svcprop

  * [dns](doc/dns.md)
  * [ldap](doc/ldap.md)
  * [nis](doc/nis.md)
  * [nsswitch](doc/nsswitch.md)

* Image Pacakging System \(IPS\) configuration via pkg[^1]

  * [pkg\_facet](doc/pkg_facet.md)
  * [pkg\_mediator](doc/pkg_mediator.md)
  * [pkg\_publisher](doc/pkg_publisher.md)
  * [pkg\_variant](doc/pkg_variant.md)

* Solaris Integrated Load Balancer \(ILB\) via ilbadm

  * [ilb\_server](doc/ilb_server.md)
  * [ilb\_servergroup](doc/ilb_servergroup.md)
  * [ilb\_healthcheck](doc/ilb_healthcheck.md)
  * [ilb\_rule](doc/ilb_rule.md)

* Solaris Elastic Virtual Switch \(EVS\)  via evsadm

  * [evs](doc/evs.md)
  * [evs\_ipnet](doc/evs_ipnet.md)
  * [evs\_properties](doc/evs_properties.md)
  * [evs\_vport](doc/evs_vport.md)

* Service Management Facility \(SMF\) Properties via svccfg, svcprop

  * [svccfg](doc/svccfg.md)


* IP Interface Configuration via ipadm

  * [address\_object](doc/address_object.md)
  * [address\_properties](doc/address_properties.md)
  * [interface\_properties](doc/interface_properties.md)
  * [ip\_interface](doc/ip_interface.md)
  * [ipmp\_interface](doc/ipmp_interface.md)
  * [protocol\_properties](doc/protocol_properties.md)
  * [vni\_interface](doc/vni_interface.md)

* Datalink Management via dladm

  * [etherstub](doc/etherstub.md)
  * [ip\_tunnel](doc/ip_tunnel.md)
  * [link\_aggregation](doc/link_aggregation.md)
  * [link\_properties](doc/link_properties.md)
  * [solaris\_vlan](doc/solaris_vlan.md)
  * [vnic](doc/vnic.md)

* ZFS via chmod

  * [zfs\_acl](doc/zfs_acl.md)
  * [system\_attributes](doc/system_attributes.md)


Oracle Solaris Providers override the core Puppet providers for:

* Zones via zoneadm, zonecfg
  * [zone](doc/zone.md)


## Setup

For Solaris 11.x puppet module install oracle-solaris\_providers

For Solaris 12.x pkg install puppet[^2]

No additional setup or configuration is required.

### Beginning with solaris\_providers

Common activites include modifying service properties

Two ways to change the domain configuration:

1. Via svccfg

  ```ruby
   # Service is provided by Core Puppet
   # Make sure dns/client:default is running
   # Required for notification of property change   
   service { 'svc:/network/dns/client:default':
     ensure => 'running'
   }
   # Set domain to oracle.lab, dns/client:default must be refreshed to
   # write the config to /etc/resolv.conf
   svccfg { 'svc:/network/dns/client:default/:properties/config/domain':
     ensure => 'present',
     type   => 'astring',
     value  => 'oracle.lab',
     notify => Service['svc:/network/dns/client:default'];
   }
  ```

2. Via the DNS provider

  ```ruby
  # Set the domain to oracle.lab
  dns { 'current':
    domain => 'oracle.lab'
  }
  ```


Set the server for puppet\/agent 
```ruby
  # enable puppet:agent
  service { 'svc:/application/puppet:agent':
    ensure => 'running'
  }
  # configure puppet:agent, refresh the service to write puppet.conf
  svccfg { 'svc:/application/puppet:agent/:properties/config/server':
    ensure => 'present',
    type   => 'astring',
    value  => 'puppet',
    notify => Service['svc:/application/puppet:agent'],
  }
```

## Usage

See links to extracted documents listed above.

## Limitations

These modules were created for use on Oracle Solaris 11 and 12.

## Development

Contributors should issue pull requests via Github.  See the project page at:
[https:\/\/github.com\/oracle\/puppet-solaris\_providers](https://github.com/oracle/puppet-solaris_providers), [contributing](CONTRIBUTING.md), and testing.

[^1]: Package installation via Puppet Core package provider

[^2]: Solaris providers are shipped with Solaris in the oracle-solaris\_providers IPS pacakge and installed automatically with puppet. Use of the module from the Puppet Forge is possible. However, it will result in errors from pkg verify as the IPS oracle-solaris\_providers pacakge cannot be removed.

