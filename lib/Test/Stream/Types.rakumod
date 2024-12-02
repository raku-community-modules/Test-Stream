unit module Test::Stream::Types;

subset PositiveInt is export of Int where $_ > 0;

enum DiagnosticSeverity is export < comment failure todo >;

# vim: expandtab shiftwidth=4
