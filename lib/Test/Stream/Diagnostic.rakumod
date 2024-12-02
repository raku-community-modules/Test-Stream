unit class Test::Stream::Diagnostic;

use Test::Stream::Types;

has Str $.message;
has DiagnosticSeverity $.severity;
has %.more;

submethod BUILD (
    Str :$!message,
    DiagnosticSeverity:D :$!severity,
    :%!more?
) { }

# vim: expandtab shiftwidth=4
