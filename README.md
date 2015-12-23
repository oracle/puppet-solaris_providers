# solaris_providers

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with solaris_providers](#setup)
    * [What solaris_providers affects](#what-solaris_providers-affects)
    * [Beginning with solaris_providers](#beginning-with-solaris_providers)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

The Oracle Solaris Providers module includes Solaris-specific implementations of
types and providers.  These include some common features as well as features
found exclusively on Oracle Solaris.

## Module Description

The Oracle Solaris Providers module currently enables configuration of the
following:

  * DNS, LDAP and NIS naming services
  * Package facets, mediators, publishers and variants

Many more types and providers will be added in the future.

## Setup

### What solaris_providers affects

The naming providers included in this module make changes to the SMF properties of the following services:

svc:/network/dns/client  
svc:/network/ldap/client  
svc:/network/nis/client  
svc:/network/nis/domain  

The package providers modify the configuration of IPS.

### Beginning with solaris_providers

For Solaris 11.x puppet module install oracle-solaris_providers  
For Solaris 12.x pkg install puppet/oracle-solaris_providers  

## Usage

Use the puppet describe command to see the properties for each of the defined
providers: dns, ldap, nis, pkg_facet, pkg_mediator, pkg_publisher, pkg_variant

## Reference

The naming providers interact with SMF properties of the following
services using the svcprop(1) command:

svc:/network/dns/client  
svc:/network/ldap/client  
svc:/network/nis/client  
svc:/network/nis/domain  

The package providers interact with IPS using the pkg(1) command.

## Limitations

These modules were created for use on Oracle Solaris 11 and 12.

## Development

Contributors should issue pull requests via Github.  See the project page at:
https://github.com/oraclesolaris/puppet-module

