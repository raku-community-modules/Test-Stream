use v6;

unit module Test::Stream;

use Test::Stream::Diagnostic;
use Test::Stream::Types;

role Event {
    use Test::Stream::EventSource;

    has Test::Stream::EventSource $.source = Test::Stream::EventSource.new(
        frame => CallFrame.new( :level(1) ),
    );

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

class Event::Suite::Start does Event does Event::Named { }

class Event::Suite::End does Event does Event::Named does Event::PassFail { }

class Event::Test does Event does Event::Named does Event::PassFail {
    has Test::Stream::Diagnostic $.diagnostic;
}

class Event::Bail does Event {
    has Str $.reason;
}

class Event::Diag does Event {
    has Str $.message;
}

class Event::Note does Event {
    has Str $.message;
}

class Event::Plan does Event {
    has PositiveInt $.planned;
}

class Event::SkipAll does Event {
    has Str $.reason;
}

#| Shared role for events that modify future tests (skip & todo).
role Event::TestModifier {
    has PositiveInt $.count;
    has Str $.reason;
}

class Event::Skip does Event does Event::TestModifier { }

class Event::Todo does Event does Event::TestModifier { }
