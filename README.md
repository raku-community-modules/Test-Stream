# Test::Stream

This is a prototype of an event-based test framework. The goal is to produce
an underlying set of modules that can be shared by all Test modules in the
Raku ecosystem. Building this on top of an abstract test event system makes
integrating different modules much easier. It also makes testing your test
modules *much* easier, and allows for output formats besides TAP.

Please note that the namespaces are likely to change in the future, so please
do not rely on this code yet.

# LICENSE

This module is licensed under the [Artistic License](LICENSE)
