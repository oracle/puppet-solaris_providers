# 2.0.0
  *Puppet 4 related changes and Bug Fixes*
## Incompatible Changes:
* NIS provider securenets argument changes from an Array to an Array of Arrays
  * Previous versions indicated secure nets must be a Hash in error messages
    ```ruby
    :securenets => ['host','1.1.1.1']
    ```
    ```ruby
    :securenets => [['host','1.1.1.1']]
    :securenets => [['host','1.1.1.1'],['255.255.255.0','2.2.2.2']]
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

## Impacting Changes
* interface_properties
  * `interface` has been renamed `name`.
  * `name` should be defined as an ip interface `net0`
  * properties should be defined as a complex hash of
    `{ proto => { prop => value }}`
  * Old style interface (name) definitions `net0/ipv4` continue to work

###  Bugs Fixes and Enhancements:
* 23593308 rspec tests need to be written for solaris_providers ipmp_interface
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
* 25192742 puppet svccfg shouldn't try to update properties for a non-existent fmri
* 25196056 puppet interface and address _properties namevars are problematic
* 25191982 puppet type 'dns' is not able to set 'options' property in resolv.conf
* 25211935 puppet link_aggregation needs to permanently delete before modifying temporary
* 25217063 puppet protocol_properties is not idempotent

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
