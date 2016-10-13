2.0.0
  Incompatible Changes:
  * NIS provider securenets argument changes from an Array to an Array of Arrays
    ```ruby
    :securenets => ['host','1.1.1.1']
    ```
    ```ruby
    :securenets => [['host','1.1.1.1']]
    :securenets => [['host','1.1.1.1'],['255.255.255.0','2.2.2.2']]
    ```

  * link_aggregation now strictly checks option combinations which previously
    failed during catalog application.
    i.e. temporary interfaces cannot be enable true/false
    static interfaces do not accept seconds as an argument
    Note: dhcp is a temporary interface

  Bugs Fixed:
  24836004 '-' is valid in pkg mediator implementation
  24836209 nis provider needs to support multiple securenets entries
  24696809 Puppet link aggregation modules cascading errors

1.2.2
This release unifies the source for the oracle-solaris_providers IPS package.
Puppet Forge Packages will not be built from this branch until spec testing has been completed.

This release changes embedded licenses from CDDL to Apache 2.0

  Bugs Fixed:
  23641391 Do not enable permanent addresses for ipadm
  23586971 Puppet link aggregation code needs to be updated based on the dladm command chan
  23593312 rspec tests need to be written for solaris_providers link_aggregation
  21626572 svccfg provider does not support multi-valued properties
  23484766 describe output for interface_properties should reference ipadm(8)
  22259529 pkg_mediator fails on previously set implementation parameter 
  23332786 Solaris NIS provider needs to validate securenets parameter
  23338926 Puppetx / PuppetX namespace change

1.2.1
This release unifies the source for the oracle-solaris_providers IPS package.
Puppet Forge Packages will not be built from this branch until spec testing has been completed.

  Bugs Fixed:
  21626572 svccfg provider does not support multi-valued properties
  23484766 describe output for interface_properties should reference ipadm(8)
  22259529 pkg_mediator fails on previously set implementation parameter
  23332786 Solaris NIS provider needs to validate securenets parameter
  23338926 Puppetx / PuppetX namespace change

1.0.2
  Version as once released on the Forge
