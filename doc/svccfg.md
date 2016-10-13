
svccfg
======
Manage SMF service properties with svccfg(8).


Parameters
----------

- **ensure**
    Valid values are `present`, `absent`, `delcust`. 

- **fmri**
    SMF service FMRI to manipulate

- **name**
    The symbolic name for properties to manipulate.  When provided as the
    fully composed property FMRI <fmri>/properties:/<property> :fmri,
    :property, and :prop_fmri will be auto-populated.

- **prop_fmri**
    The fully composed property FMRI <fmri>/properties:/<property>
    if left blank it will be built from the :fmri and :property
    parameters, or from :name if the format matches

- **property**
    Name of property - includes Property Group and Property.  If
    the service, instance, or property group does not exist, they
    will be created.

- **type**
    Type of the property. Type must be defined for server side :value
    validation See scf_value_create(3SCF)
    Valid values are `count`, `integer`, `opaque`, `host`, `hostname`,
    `net_address`, `net_address_v4`, `net_address_v6`, `time`, `astring`,
    `ustring`, `boolean`, `fmri`, `uri`, `dependency`, `framework`,
    `configfile`, `method`, `template`, `template_pg_pattern`,
    `template_prop_pattern`. 

- **value**
    Value of the property. Value types :fmri, :opaque, :host, :hostname,
    :net_address, :net_address_v4, :net_address_v6, and :uri are treated as
    lists if they contain whitespace. See scf_value_create(3SCF)

Providers
---------
    svccfg
