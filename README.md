[![Actions Status](https://github.com/raku-community-modules/Test-Stream/actions/workflows/linux.yml/badge.svg)](https://github.com/raku-community-modules/Test-Stream/actions) [![Actions Status](https://github.com/raku-community-modules/Test-Stream/actions/workflows/macos.yml/badge.svg)](https://github.com/raku-community-modules/Test-Stream/actions)

NAME
====

Test::Stream - Stream test events

SYNOPSIS
========

```raku
use Test::Stream;
```

DESCRIPTION
===========

This is a prototype of an event-based test framework. The goal is to produce an underlying set of modules that can be shared by all Test modules in the Raku ecosystem. Building this on top of an abstract test event system makes integrating different modules much easier. It also makes testing your test modules *much* easier, and allows for output formats besides TAP.

AUTHOR
======

Dave Rolsky

COPYRIGHT AND LICENSE
=====================

Copyright 2016 Dave Rolsky

Copyright 2020 - 2024 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

