# 2.1.0
## New Features
* boot_environment
  * Now shows the created timestamp of the BE
* pkg_publisher
  * supports unique proxies, ssl certs, and ssl keys per origin

## Impacting Changes
* boot_environemnt
  * Providing a value which does not match the running state to 'running' is now
    an error instead of a warning. The running value should not be provided
    except as a mechanism to detect a change in the running BE.
* pkg_publisher
  * origin and mirror now enforce URI specification http(s)|file://
  * sslcert and sslkey files are autorequired
  * searchbefore and searchafter publishers are now autorequired

## Bugs Fixes and Enhancements
* 26137448 puppet pkg_publisher does not work for slightly complex configurations
* 26137407 puppet pkg_publisher provider is not idempotent with ssl certs and keys
* 26452898 puppet boot_environment should show created timestamp
* 26486256 puppet pkg_publisher fails if sslcert or sslkey are nil
* 26486276 puppet pkg_publisher rspec code needs to be re-written

# 2.0.2
## Impacting Changes
* svccfg
  * Property groups will be automatically created with the type 'application' if
    they do not exist
  * Property group types can be a user defined string

## Bugs Fixes and Enhancements
* 25661234 puppet solaris_provider should allow free strings for smf pg types

# 2.0.1
## Bugs Fixes and Enhancements
* 23593309 rspec tests need to be written for solaris_providers link_properties
* 25416733 puppet nsswitch does not accept user as a printer database
* 25416766 puppet module regressions 2.0.0
* 25438739 puppet zone provider does not understand 'unavailable' state

# 2.0.0
  *Puppet 4 related changes and Bug Fixes*
## Incompatible Changes
* NIS provider securenets argument changes from an Array of components allowing
  a single entry to an Array of string entries.
  * Previous versions indicated securenets must be a Hash in error messages.
  * Incorrect Format did not allow multiple `'host'` definitions
  ```Ruby
    :securenets => {'host' => '1.1.1.1'}
  ```
  * Old Correct Format allowed one entry
  ```Ruby
    :securenets => ['host','1.1.1.1']
  ```
  * New Format
  ```Ruby
    :securenets => ['1.1.1.1']
    :securenets => ['1.1.1.1','2.2.2.2/255.255.255.0']
  ```
  * Allowed Format
  ```Ruby
    :securenets => ['host/1.1.1.1']
    :securenets => ['1.1.1.1/host','2.2.2.2/255.255.255.0']
  ```
* link_aggregation
  * now strictly checks option combinations which previously failed during
    catalog application.
  * i.e. temporary interfaces cannot be enable true/false static interfaces do
    not accept seconds as an argument *Note*: dhcp is a temporary interface
  * resources are considered invalid if they do not define `:lower_links`
* interface_properties
  * no longer supports the parameter `interface` instead uses `name`. This
    change should be transparent.
* address_properties
  * no longer supports the parameter `address` instead uses `name`. This change
    should be transparent.
* protocol_properties
  * no longer supports the parameter `protocol` instead uses `name`. This change
    should be transparent.
* LDAP, DNS, and NIS
  * Names for these resources must be the string `current` other names are
    unable to be identified via puppet resource and will not appear to be in
    sync.
* svccfg
  * FMRI arguments `fmri` and `prop_fmri` must now be well formed.
    * `svc:/system/system-log:rsyslog` vs `system-log:rsyslog` or
      `system/system-log:rsyslog`

## Impacting Changes
* interface_properties
  * `interface` has been renamed `name`.
  * `name` should be defined as an ip interface i.e. `net0`
  * properties should be defined as a complex hash of
    `{ proto => { prop => value }}`
  * Old style interface (name) definitions `net0/ipv4` continue to work
* svccfg
  * Property groups will NO LONGER be automatically created. Previously defining
    a property => 'foo/bar' would have created the property group 'foo' on the
    first run and set the property 'foo/bar' on the second run. Puppet will now
    fail if the property group does not exist or will not be created.
    SEE: 2.0.2 for updates to this change
  ```Ruby
    svccfg { 'svc:/system/system-log:rsyslog/:properties/config':
      ensure    => 'present',
      type      => 'configfile',
    }
  ```
  ```Ruby
    svccfg { 'svc:/system/system-log:rsyslog/:properties/config/log_from_remote':
      ensure    => 'present',
      type      => 'boolean',
      value     => 'false',
    }
  ```
  * resource names should be provided as the fully qualified fmri of the
    property svc:/<fmri>[:<instance>]/:properties/<property>
  * the non-standard type array must be used with string type properties
    astring, ustring, and opaque when they are being used as a list argument.
    *NOTE* When used as a native string type the array will be joined into a
    single string and the resource will not be idempotent.
  * svccfg is only idempotent when any of the following are true
    * The property name is fully qualified. To help acheive this
      `title_patterns` are used to extract details from fully qualified names.
  ```Ruby
    svccfg { 'svc:/system/system-log:rsyslog/:properties/config/log_from_remote':
      ensure    => 'present',
      type      => 'boolean',
      value     => 'false',
    }
  ```
    * `prop_fmri` matches the fully qualified property name
  ```Ruby
    svccfg { 'foo':
      prop_fmri => 'svc:/system/system-log:rsyslog/:properties/config/log_from_remote',
      ensure    => 'present',
      type      => 'boolean',
      value     => 'false',
    }
  ```
    * `fmri` and `property` are specified exactly as found in smf
  ```Ruby
    svccfg { 'foo':
      fmri      => 'svc:/system/system-log:rsyslog',
      property  => 'config/log_from_remote',
      ensure    => 'present',
      type      => 'boolean',
      value     => 'false',
    }
  ```
* boot_environments
  * Puppet will now fail if a non-existent boot environment is provided as the
    argument for clone_be
  * zpool is ignored if clone_be is provided
  * The new read only/ignored property running has been added to allow puppet
    resource boot_environment output to indicate both the activate and running
    BE.


###  Bugs Fixes and Enhancements:
* 19429313 address_object type should support vrrp addresses
* 19888183 publisher provider is applied on each puppet run
* 22072780 pkg_publisher provider applies 'searchfirst' every time
* 22125767 nsswitch provider missing ipnodes, protocols
* 22126108 add process scheduler administration provider
* 23593229 rspec tests need to be written for solaris_providers boot_environment
* 23593308 rspec tests need to be written for solaris_providers ipmp_interface
* 23593316 rspec tests need to be written for solaris_providers protocol_properties
* 23593319 rspec tests need to be written for solaris_providers vnic
* 23593225 rspec tests need to be written for solaris_providers etherstub
* 23593310 puppet module rspec tests and validation for nsswitch
* 24696809 Puppet link aggregation modules cascading errors
* 24836004 '-' is valid in pkg mediator implementation
* 24836209 nis provider needs to support multiple securenets entries
* 25022632 puppet ipmp_interface type should not validate interface existence
* 25022632 puppet ipmp_interface type should not validate interface existence
* 25022714 Puppet SMF service should not refresh on every apply operation
* 25071681 puppet dns resource generates invalid manifest
* 25071686 puppet resource ldap; Error: Could not run: No ability to determine if ldap...
* 25071690 puppet resource nis; Error: Could not run: No ability to determine if nis exists
* 25106150 Nis provider is not idempotent
* 25106155 DNS provider is not idempotent
* 25163776 puppet link_aggregation misunderstands 'address' -u output
* 25163791 puppet link_aggregation should use resource values instead of property_hash
* 25163815 puppet address_object errors and validations could be better
* 25163840 puppet puppet::property::list types conflict with internally generated arrays
* 25163864 puppet link_aggregation type specs need to be written
* 25177901 puppet beadm should not use both -e and -p
* 25178928 puppet link_aggregation should try to copy existing values on change of mode
* 25179040 puppet link_aggregation should delete with -t for temporary
* 25191982 puppet type 'dns' is not able to set 'options' property in resolv.conf
* 25192742 puppet svccfg shouldn't try to update properties for a non-existent fmri
* 25196056 puppet interface and address _properties namevars are problematic
* 25211935 puppet link_aggregation needs to permanently delete before modifying temporary
* 25217063 puppet protocol_properties is not idempotent
* 25218036 puppet resource svccfg emits a warning for every property
* 25218053 puppet svccfg prefetch should match individually specified parameters
* 25218208 puppet svccfg should enforce well-formedness in fmri parameters
* 25224661 puppet resource address_properties shouldn't output read-only properties
* 25224777 puppet address_properties should not reset unchanged properties
* 25225039 puppet svccfg should not declare a property absent if it does not match desired
* 25306835 puppet boot_environment needs to understand the new snapshot format
* 25306877 puppet svccfg should check for pg and allow nested property groups
* 25306904 puppet dns,nis,ldap,protocol_properties prefetch fails after input auto munge
* 25348321 puppet boot_environment needs to validate all properties and parameters
* 25354751 puppet vnic provider needs to support / and - as valid vnic name characters

# 1.2.3 (Unreleased)
## New Features
* Solaris Integrated Load Balancer (ILB) support
  * ilb_healthcheck
  * ilb_rule
  * ilb_server
  * ilb_servergroup
* Manage NFSv4 ACL Specifications on ZFS Files
  * zfs_acl

###  Bugs Fixes and Enhancements:
* 22960016 Puppet needs a native way to set ZFS ACLs
* 23547788 Add ILB type to Puppet

# 1.2.2
This release unifies the source for the oracle-solaris_providers IPS package.
~~Puppet Forge Packages will not be built from this branch until
spec testing has been completed.~~

This release changes embedded licenses from CDDL to Apache 2.0

###  Bugs Fixed:
* 21626572 svccfg provider does not support multi-valued properties
* 22259529 pkg_mediator fails on previously set implementation parameter
* 23332786 Solaris NIS provider needs to validate securenets parameter
* 23338926 Puppetx / PuppetX namespace change
* 23484766 describe output for interface_properties should reference ipadm(8)
* 23586971 Puppet link aggregation code needs to be updated based on the dladm command chan
* 23593312 rspec tests need to be written for solaris_providers link_aggregation
* 23641391 Do not enable permanent addresses for ipadm

# 1.2.1
This release unifies the source for the oracle-solaris_providers IPS package.
Puppet Forge Packages will not be built from this branch until spec testing has been completed.

###  Bugs Fixed:
* 21626572 svccfg provider does not support multi-valued properties
* 22259529 pkg_mediator fails on previously set implementation parameter
* 23332786 Solaris NIS provider needs to validate securenets parameter
* 23338926 Puppetx / PuppetX namespace change
* 23484766 describe output for interface_properties should reference ipadm(8)

# 1.0.2
  Version as once released on the Forge
