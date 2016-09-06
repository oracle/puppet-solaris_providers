
pkg_mediator
============
Manage Oracle Solaris package mediators


Parameters
----------

- **ensure**
    The basic property that the resource should be in.
    Valid values are `present`, `absent`. 

- **implementation**
    The implementation of the mediated interface to use
    Values can match `/none/i`, `/\A[[:alnum:]]+\Z/`,
    `/\A[[:alnum:]]+@(?:\d+(?:\.\d+){0,})\Z/`.

- **name**
    The mediator name

- **version**
    The version of the mediated interface to use
    Values can match `/none/i`, `/\A\d+(?:\.\d+){0,}\Z/`.

Providers
---------
    pkg_mediator
