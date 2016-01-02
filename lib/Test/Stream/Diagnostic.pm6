use v6;

unit class Test::Stream::Diagnostic;

use Test::Stream::Types;

has Str $.message;
has DiagnosticSeverity $.severity;
has %.more;

submethod BUILD (
    Str:D :$!message,
    DiagnosticSeverity:D :$!severity,
    :%!more?
) { }

