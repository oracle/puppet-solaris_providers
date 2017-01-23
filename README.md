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
* Naming Services via svccfg, svcprop
* Image Pacakging System (IPS) configuration via pkg
* Solaris Integrated Load Balancer (ILB) via ilbadm
* Solaris Elastic Virtual Switch (EVS)  via evsadm
* Service Management Facility (SMF) Properties via svccfg, svcprop
* IP Interface Configuration via ipadm
* Datalink Management via dladm
* ZFS ACLs and file Attributes via chmod

Oracle Solaris Providers override the core Puppet providers for:

* Zones via zoneadm, zonecfg

### See [documentation index](docs/_index.html) for details

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

