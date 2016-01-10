use v6;

unit module Test::Stream;

use Test::Stream::Diagnostic;
use Test::Stream::Types;

role Event {
    use Test::Stream::EventSource;

    has Test::Stream::EventSource $.source;
    has Instant:D $.time = now;

    method type {
        return self.^name.subst( rx{ ^ 'Test::Stream::Event::' }, q{} );
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
    submethod BUILD (Str:D :$!name) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::Suite::End does Event does Event::Named {
    submethod BUILD (Str:D :$!name) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::Test does Event does Event::Named does Event::PassFail {
    has Test::Stream::Diagnostic $.diagnostic;
    submethod BUILD (Str :$!name, Test::Stream::Diagnostic :$!diagnostic, Bool:D :$!passed) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::Bail does Event {
    has Str $.reason;
    submethod BUILD (Str :$!reason) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::Diag does Event {
    has Str $.message;
    submethod BUILD (Str :$!message) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::Note does Event {
    has Str $.message;
    submethod BUILD (Str :$!message) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::Plan does Event {
    has PositiveInt $.planned;
    submethod BUILD (PositiveInt:D :$!planned) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::SkipAll does Event {
    has Str $.reason;
    submethod BUILD (Str :$!reason) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::Skip does Event {
    has PositiveInt $.count;
    has Str $.reason;
    submethod BUILD (PositiveInt:D :$!count, Str :$!reason) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::Todo::Start does Event {
    has Str $.reason;
    submethod BUILD (Str :$!reason) {
        $!source = Test::Stream::EventSource.new;
    }
}

class Event::Todo::End does Event {
    has Str $.reason;
    submethod BUILD (Str :$!reason) {
        $!source = Test::Stream::EventSource.new;
    }
}
