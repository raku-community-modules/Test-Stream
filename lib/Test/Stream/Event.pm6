use v6;

unit module Test::Stream;

use Test::Stream::Diagnostic;
use Test::Stream::EventSource;
use Test::Stream::Types;

role Event {
    has Test::Stream::EventSource $.source;
    has Instant:D $.time = now;

    method type {
        return self.^name.subst( rx{ ^ 'Test::Stream::Event::' }, q{} );
    }

    method set-source (Test::Stream::EventSource:D $source) {
        $!source = $source;
    }
}

#| Shared role events that have a name (subtest-related and test events).
role Event::Named {
    has Str $.name;
}

#| Shared role for events that indicate pass-fail for a named thing (tests,
#| subtests, etc.)
role Event::PassFail {
    has Bool $.passed;
}

class Event::Suite::Start does Event does Event::Named {
    submethod BUILD (Str:D :$!name) { }
}

class Event::Suite::End does Event does Event::Named {
    has Int  $.tests-planned;
    has Int  $.tests-run;
    has Int  $.tests-failed;
    has Bool $.passed;
    submethod BUILD (
        Str:D  :$!name,
        Int    :$!tests-planned,
        Int:D  :$!tests-run,
        Int:D  :$!tests-failed,
        Bool:D :$!passed,
    ) { }
}

class Event::Test does Event does Event::Named does Event::PassFail {
    has Test::Stream::Diagnostic $.diagnostic;
    submethod BUILD (
        Str :$!name,
        Test::Stream::Diagnostic :$!diagnostic,
        Bool:D :$!passed,
    ) { }
}

class Event::Bail does Event {
    has Str $.reason;
    submethod BUILD (Str :$!reason) { }
}

class Event::Diag does Event {
    has Str $.message;
    submethod BUILD (Str :$!message) { }
}

class Event::Note does Event {
    has Str $.message;
    submethod BUILD (Str :$!message) { }
}

class Event::Plan does Event {
    has PositiveInt $.planned;
    submethod BUILD (PositiveInt:D :$!planned) { }
}

class Event::SkipAll does Event {
    has Str $.reason;
    submethod BUILD (Str :$!reason) { }
}

class Event::Skip does Event {
    has PositiveInt $.count;
    has Str $.reason;
    submethod BUILD (
        PositiveInt:D :$!count,
        Str :$!reason,
    ) { }
}

class Event::Todo::Start does Event {
    has Str $.reason;
    submethod BUILD (Str :$!reason) { }
}

class Event::Todo::End does Event {
    has Str $.reason;
    submethod BUILD (Str :$!reason, Test::Stream::EventSource :$!source) { }
}
