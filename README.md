# solaris_providers Module for Puppet

[![Build Status](https://travis-ci.org/oracle/puppet-solaris_providers.svg?branch=master)](https://travis-ci.org/oracle/puppet-solaris_providers)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with solaris_providers](#setup)
  * [What solaris_providers affects](#what-solaris_providers-affects)
  * [Beginning with solaris_providers](#beginning-with-solaris_providers)
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

  * [boot_environment](doc/boot_environment.md)

* Naming Services via svccfg, svcprop
  * [dns](doc/dns.md)
  * [ldap](doc/ldap.md)
  * [nis](doc/nis.md)
  * [nsswitch](doc/nsswitch.md)
* Image Pacakging System (IPS) configuration via pkg
  * [pkg_facet](doc/pkg_facet.md)
  * [pkg_mediator](doc/pkg_mediator.md)
  * [pkg_publisher](doc/pkg_publisher.md)
  * [pkg_variant](doc/pkg_variant.md)
* Solaris Integrated Load Balancer (ILB) via ilbadm
  * [ilb_server](doc/ilb_server.md)
  * [ilb_servergroup](doc/ilb_servergroup.md)
  * [ilb_healthcheck](doc/ilb_healthcheck.md)
  * [ilb_rule](doc/ilb_rule.md)
* Solaris Elastic Virtual Switch (EVS)  via evsadm
  * [evs](doc/evs.md)
  * [evs_ipnet](doc/evs_ipnet.md)
  * [evs_properties](doc/evs_properties.md)
  * [evs_vport](doc/evs_vport.md)
* Service Management Facility (SMF) Properties via svccfg, svcprop
  * [svccfg](doc/svccfg.md)
* IP Interface Configuration via ipadm
  * [address_object](doc/address_object.md)
  * [address_properties](doc/address_properties.md)
  * [interface_properties](doc/interface_properties.md)
  * [ip_interface](doc/ip_interface.md)
  * [ipmp_interface](doc/ipmp_interface.md)
  * [protocol_properties](doc/protocol_properties.md)
  * [vni_interface](doc/vni_interface.md)
* Datalink Management via dladm
  * [etherstub](doc/etherstub.md)
  * [ip_tunnel](doc/ip_tunnel.md)
  * [link_aggregation](doc/link_aggregation.md)
  * [link_properties](doc/link_properties.md)
  * [solaris_vlan](doc/solaris_vlan.md)
  * [vnic](doc/vnic.md)
* ZFS via chmod
  * [zfs_acl](doc/zfs_acl.md)
  * [system_attributes](doc/system_attributes.md)

Oracle Solaris Providers override the core Puppet providers for:

* Zones via zoneadm, zonecfg
  * [zone](doc/zone.md)

## Setup

For Solaris 11.x puppet module install oracle-solaris_providers

For Solaris 12.x pkg install puppet

No additional setup or configuration is required.

### Beginning with solaris_providers

Common activities include modifying service properties

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


Set the server for puppet/agent
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

Contributors should issue pull requests via Github see [contributing](CONTRIBUTING.md) and [testing](TESTING.md).


### Notes
Package installation is via Puppet Core package provider

Solaris providers are shipped with Solaris in the oracle-solaris_providers IPS package and installed automatically with puppet. Use of the module from the Puppet Forge is possible. However, it will result in errors from pkg verify as the IPS oracle-solaris_providers package cannot be removed.

