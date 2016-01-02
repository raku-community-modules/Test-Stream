use v6;

unit module Test::Stream;

use Test::Stream::Types;

role Event {
    use Test::Stream::EventSource;

    has Test::Stream::EventSource $.source;

    has Instant:D $.time = now;

    method name {
        return self.^name.split(rx{'::'})[*-1];
    }
}

#| Shared role events that have a name (subtest-related and test events).
role Event::Named does Event {
    has Str $.name;
    submethod BUILD (Str:D :$!name) { }
}

#| Shared role for events that indicate pass-fail for a named thing (tests,
#| subtests, etc.)
role Event::PassFail does Event {
    has Bool $.passed;
    submethod BUILD (Bool:D :$!passed) { }
}

role Event::Suite::Start does Event::Named { }

role Event::Suite::End does Event::Named does Event::PassFail { }

class Event::Diagnostic {
    has Str $.message;
    has DiagnosticSeverity $.severity;
    has $.got;
    has Str $.operator;
    has $.expected;
    submethod BUILD (
        Str:D :$!message,
        DiagnosticSeverity:D :$!severity,
        Any :$!got?,
        Str:D :$!operator?,
        Any :$!expected?,
    ) { }
}

role Event::Test does Event::PassFail {
    has Event::Diagnostic $.diagnostic;
    submethod BUILD (Event::Diagnostic:D :$diagnostic) { }
}

role Event::Bail does Event {
    has Str $.reason;
}

role Event::Diag does Event {
    has Str $.message;
    submethod BUILD (Str:D :$!message) { }
}

role Event::Plan does Event {
    has PositiveInt $.planned;
}

role Event::SkipAll does Event {
    has Str $.reason;
    submethod BUILD (Str:D :$!reason) { }
}

#| Shared role for events that modify future tests (skip & todo).
role Event::TestModifier does Event {
    has PositiveInt $.count;
    has Str $.reason;
    submethod BUILD (PositiveInt :$!count, Str:D :$!reason) { }
}

role Event::Skip does Event::TestModifier { }

role Event::Todo does Event::TestModifier { }
