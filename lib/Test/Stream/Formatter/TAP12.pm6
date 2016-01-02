use v6;

use Test::Stream::Listener;

unit class Test::Stream::Formatter::TAP12 does Test::Stream::Listener;

use Test::Stream::Types;

my class TodoState {
    has PositiveInt $.count;
    has Str $.reason;
    submethod BUILD (Str:D :$!reason, PositiveInt:D :$!count) { }

    method did-todo {
        $.count--;
    }
}

my class Suite {
    has Instant $.started-at;
    has Str $.name;
    has Int $.planned is rw;
    has Int:D $.test-num = 0;
    has Bool $.said-plan is rw = False;

    has TodoState $.todo-state;

    submethod BUILD (
        Instant:D :$!started-at,
        Str:D :$!name,
        Int :$!planned?,
    ) { }

    subset NumBoolPair of List where *.elems == 2 && *[0] ~~ Int:D && *[1] ~~ Bool:D;
    method next-test (--> NumBoolPair) {
        $.test-num++;

        my $is-todo = $.todo-state.defined;
        if $.todo-state {
            $.todo-state.did-todo;
            $.todo-state = (TodoState) unless $.todo-state.count;
        }
        return ( $.test-num, $is-todo );
    }

    method start-todo (|a) {
        $.todo-state = TodoState.new(|a);
    }

    method in-todo (--> Bool) {
        return $.todo-state.defined;
    }

    method has-plan (--> Bool) {
        return $.planned.defined;
    }
}

has Suite @suites;
has IO::Handle $.output = $*OUT;
has IO::Handle $.todo-output = $*OUT;
has IO::Handle $.failure-output = $*ERR;

multi method accept-event (Test::Stream::Event::Suite::Start:D $event) {
    # We want this comment to appear at the _current_ indentation level, not
    # indented for the subtest that we're starting.
    if @.suites.elems > 0 {
        self!say-comment( $.output, q{Subtest } ~ $event.name );
    }

    @.suites.append: Suite.new(
        name       => $event.name,
        started-at => $event.time,
    );
}

multi method accept-event (Test::Stream::Event::Suite::End:D $event) {
    self!die-unless-suites($event);

    my $suite = @.suites.pop;
    unless $suite.name eq $event.name {
        die "Recieved a Suite::End event named {$event.name} but the most recent suite is named {$suite.name}";
    }

    unless $suite.said-plan {
        self!say-plan( $suite.test-num );
    }

    if @.suites {
        my $now = now;
        self!comment(
            "Started at {$suite.started-at}"
            ~ " - ended at {$now}"
            ~ " - elapsed time is {$now - $suite.started-at}s"
        );
    }
    else {
        self!end-test-run;
    }
}

multi method accept-event (Test::Stream::Event::Plan:D $event) {
    self!die-unless-suites($event);

    self!current-suite.planned = $event.planned;
    self!say-plan( $event.planned );
    self!current-suite.said-plan(True);
}

multi method accept-event (Test::Stream::Event::SkipAll:D $event) {
    self!die-unless-suites($event);

    if self!current-suite.test-num > 0 {
        die "Received a SkipAll event but the current suite has already run {self!current-suite.test-num} tests";
    }

    self!say-plan( 0, $event.reason );
}

multi method accept-event (Test::Stream::Event::Diag:D $event) {
    self!die-unless-suites($event);

    my $output =
        self!current-suite.in-todo
        ?? $.todo-output
        !! $.failure-output;

    self!say-comment( $output, $event.message );
}

multi method accept-event (Test::Stream::Event::Test:D $event) {
    self!die-unless-suites($event);

    my ( $test-num, $todo-reason ) = self!current-suite.next-test;

    self!say-test-status(
        ok          => $event.passed,
        number      => $test-num,
        name        => $event.name,
        todo-reason => $todo-reason,
        diagnostic  => $event.diagnostic,
    );
}

multi method accept-event (Test::Stream::Event::Skip:D $event) {
    self!die-unless-suites($event);

    for 1..$event.tests {
        # We don't care if the test is marked as TODO, since we're skipping it
        # anyway.
        my ( $test-num, ) = self!current-suite.next-test;
        self!say-test-status(
            ok          => True,
            number      => $test-num,
            skip-reason => $event.reason,
        );
    }
}

multi method accept-event (Test::Stream::Event::Bail:D $event) {
    self!die-unless-suites($event);

    my $bail = 'Bail out!';
    $bail ~= " {$event.reason}" if $event.reason;
    # This should never be indented.
    self.output.say($bail);
}

multi method accept-event (Test::Stream::Event::Todo:D $event) {
    self!die-unless-suites($event);

    self!current-suite.start-todo(
        count  => $event.count,
        reason => $event.reason,
    );
}

method !die-unless-suites (Test::Stream::Event:D $event) {
    return if @.suites.elems;
    die "Received a {$event.name} event but there are no suites currently in progress";
}

method !current-suite {
    return @.suites[*-1];
}

method !say-plan (Int:D $count, Str $skip) {
    my $plan-line = '1..' ~ $count;
    if $skip.defined {
        $plan-line ~= " # Skipped: $skip";
    }
    self!say-indented( $.output, $plan-line );
}

method !say-test-status (
    Bool:D :$ok,
    PositiveInt:D :$number,
    Str:D :$name?,
    Str:D :$todo-reason,
    Str:D :$skip-reason,
    Test::Stream::Event::Diagnostic :$diagnostic?,
) {
    my $status-line = ( !$ok ?? q{not } !! q{} ) ~ "ok $number";
    if $todo-reason.defined {
        $status-line ~= q{ # TODO } ~ escape($todo-reason);
    }
    elsif $skip-reason.defined {
        $status-line ~= q{ # skip } ~ escape($skip-reason);
    }
    elsif $name.defined {
        $status-line ~= q{ } ~ escape($name);
    }

    self!say-indented( $.output, $status-line );
    self!maybe-say-diagnostic( $diagnostic, $todo-reason.defined );
}

method !maybe-say-diagnostic (Test::Stream::Event::Diagnostic $diagnostic, Bool:D $is-todo)  {
    return unless $diagnostic.defined;

    my $output =
        $is-todo
        ?? $.todo-output
        !! $diagnostic.severity eq 'failure'
        ?? $.failure-output
        !! $.output;

    self!say-comment( $output, $diagnostic.message )
        if $diagnostic.message.defined;
    if $diagnostic.got.defined && $diagnostic.expected.defined {
        self!say-comment( $output, q{  expected : } ~ $diagnostic.expected.perl );
        self!say-comment( $output, q{  operator : } ~ $diagnostic.operator.perl )
            if $diagnostic.operator.defined;
        self!say-comment( $output, q{  got      : } ~ $diagnostic.got.perl )
    }
}

method !say-comment (Str:D $comment) {
    self!say-indented(
        $.output,
        $comment.lines.map( { escape($_) } ),
        :prefix('# '),
    );
}

sub escape (Str:D $text) {
    return $text.subst( :g, q{#}, Q{\#} ),
}

method !say-indented (IO::Handle:D $handle, Str :$prefix, *@text) {
    for @text.lines -> $line {
        $handle.print(
            q{ } x self!indent-level,
            ( $prefix.defined ?? $prefix !! () ),
            $line,
            "\n"
        );
    }
}

method !indent-level {
    return @.suites.elems - 1;
}
