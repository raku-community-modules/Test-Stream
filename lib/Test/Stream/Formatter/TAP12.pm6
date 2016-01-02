use v6;

use Test::Stream::Listener;

unit class Test::Stream::Formatter::TAP12 does Test::Stream::Listener;

my class SkipState {
    has Str:D $.reason;
    has Int:D $.count;
}

my class TodoState {
    has Str:D $.reason;
    has Int:D $.count;

    method did-todo {
        $.count--;
    }
}

my class Suite {
    has Str:D $.name;
    has Int $.plan is rw;
    has Int:D $.test-num = 1;
    has SkipState $.skip-state;
    has TodoState $.todo-state;
    has Bool $.said-plan = False is rw;

    method has-plan {
        return $.plan.defined;
    }
}

has Str:D @suites;
has IO::Handle $.output;
has IO::Handle $.todo-output;
has IO::Handle $.failure-output;

multi method receive-event (Test::Stream::Event::Suite::Start:D $event) {
    # We want this comment to appear at the _current_ indentation level, not
    # indented for the subtest that we're starting.
    if @suites.elems > 0 {
        self!say-comment( 'Subtest ' ~ $event.name );
    }

    @suites.append: Suite.new( name => $event.name );
}

multi method receive-event (Test::Stream::Event::Suite::End:D $event) {
    unless @suites.elems {
        die 'Received a Suite::End event but there are no suites currently in progress';
    }

    my $suite = @suites.pop;
    unless $suite.name eq $event.name {
        die "Recieved a Suite::End event named {$event.name} but the most recent suite is named {$suite.name}";
    }

    unless $suite.said-plan {
        self!say-plan( $suite.test-num );
    }
}

multi method receive-event (Test::Stream::Event::Plan:D $event) {
    unless @suites.elems {
        die 'Received a Plan event but no test Suite has been started';
    }

    my $suite = @suites[*-1];
    if $suite.has-plan {
        die "Received a Plan event but the current suite ({$suite.name}) already has a plan";
    }

    $suite.plan = $event.plan;

    self!say-plan( $event.plan );

    $suite.said-plan(True);
}

multi method receive-event (Test::Stream::Event::Diag:D $event) {
    self.comment( $event.message );
}

multi method receive-event (Test::Stream::Event::Bail:D $event) { ... }
multi method receive-event (Test::Stream::Event::Skip:D $event) { ... }
multi method receive-event (Test::Stream::Event::SkipAll:D $event) { ... }
multi method receive-event (Test::Stream::Event::Test:D $event) { ... }
multi method receive-event (Test::Stream::Event::Todo:D $event) { ... }

method !say-plan (Int:D $plan) {
    self!say-indented( '1..' ~ $plan );
}

method !say-comment (Str:D $comment) {
    self!say-indented( $.output, $comment.lines, '# ' );
}

method !say-indented (IO::Handle:D $handle, Str:D @text, Str $prefix) {
    for @test.lines {
        $handle.print(
            q{ } x self!indent-level,
            ( $prefix.defined ?? $prefix !! () ),
            $line,
            "\n"
        );
    }
}

method !indent-level {
    return @suites.elems - 1;
}
