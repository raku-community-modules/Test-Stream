use v6;

use Test::Stream::Listener;

unit class Test::Stream::Formatter::TAP12 does Test::Stream::Listener;

use Test::Stream::Diagnostic;
use Test::Stream::Types;

my class TodoState {
    has Int $.count is rw;
    has Str $.reason;
    submethod BUILD (Str:D :$!reason, Int:D :$!count) { }

    method did-todo-test {
        $.count--;
    }
}

my class Suite {
    has Instant $.started-at;
    has Str $.name;
    has Int $.planned is rw;
    has Int:D $.tests-run is rw = 0;
    # This is the _real_ count because TODO tests are printed as "not ok" but
    # they don't count as actual failures.
    has Int:D $.real-failure-count is rw = 0;
    has Bool $.said-plan is rw = False;

    has TodoState $.todo-state is rw;

    submethod BUILD (
        Instant:D :$!started-at,
        Str:D :$!name,
        Int :$!planned?,
    ) { }

    method next-test-number (--> PositiveInt:D) {
        if $.todo-state {
            $.todo-state.did-todo-test;
            $.todo-state = (TodoState) unless $.todo-state.count;
        }
        return ++$.tests-run;
    }

    method start-todo (|a) {
        $.todo-state = TodoState.new(|a);
    }

    method in-todo (--> Bool:D) {
        return $.todo-state.defined;
    }

    method todo-reason (--> Str:D) {
        return unless $.todo-state.defined;
        return $.todo-state.reason;
    }

    method record-failure {
        ++$.real-failure-count;
    }

    method has-plan (--> Bool) {
        return $.planned.defined;
    }
}

# This is the current suite stack. We push and pop onto this as we go.
has Suite @!suites;
# As we pop suites off @!suites we unshift them onto this so we always have
# access to them.
has Suite @!finished-suites;
has IO::Handle $.output = $*OUT;
has IO::Handle $.todo-output = $*OUT;
has IO::Handle $.failure-output = $*ERR;

multi method accept-event (Test::Stream::Event::Suite::Start:D $event) {
    # We want this comment to appear at the _current_ indentation level, not
    # indented for the subtest that we're starting.
    if @!suites.elems > 0 {
        self!say-comment( $.output, q{Subtest } ~ $event.name );
    }

    @!suites.append: Suite.new(
        name       => $event.name,
        started-at => $event.time,
    );
}

multi method accept-event (Test::Stream::Event::Suite::End:D $event) {
    self!die-unless-suites($event);

    unless self!current-suite.name eq $event.name {
        die "Recieved a Suite::End event named {$event.name} but the most recent suite is named {self!current-suite.name}";
    }

    self!end-current-suite;
}

multi method accept-event (Test::Stream::Event::Plan:D $event) {
    self!die-unless-suites($event);

    self!current-suite.planned = $event.planned;
    self!say-plan( $event.planned );
    self!current-suite.said-plan = True;
}

multi method accept-event (Test::Stream::Event::SkipAll:D $event) {
    self!die-unless-suites($event);

    if self!current-suite.tests-run > 0 {
        die "Received a SkipAll event but the current suite has already run {self!current-suite.tests-run} tests";
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

    my $todo-reason = self!current-suite.todo-reason;
    my $test-num = self!current-suite.next-test-number;

    self!current-suite.record-failure
        unless $event.passed || $todo-reason.defined;

    my %status = (
        ok          => ?$event.passed,
        number      => $test-num,
        name        => $event.name,
        diagnostic  => $event.diagnostic,
    );
    %status<todo-reason> = $todo-reason
        if $todo-reason.defined;

    self!say-test-status(|%status);
}

multi method accept-event (Test::Stream::Event::Skip:D $event) {
    self!die-unless-suites($event);

    for 1..$event.count {
        self!say-test-status(
            ok          => True,
            number      => self!current-suite.next-test-number,
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

class Status {
    has Int:D $.exit-code = 0;
    has Str:D $.error     = q{};
}

method finalize (--> Status:D) {
    my $unfinished-suites = @!suites.elems;
    self!end-current-suite while @!suites;

    my $top-suite = @!finished-suites[0];

    # The exit-code is going to be used as an actual process exit code so it cannot be greater than 254.q
    if $top-suite.real-failure-count > 0 {
        my $failed = 'test' ~ ( $top-suite.real-failure-count > 1 ?? 's' !! q{} );
        my $error = "failed {$top-suite.real-failure-count} $failed";
        return Status.new(
            exit-code => min( 254, $top-suite.real-failure-count ),
            error     => $error,
        );

    }
    elsif $top-suite.planned
          && ( $top-suite.planned != $top-suite.tests-run ) {
        my $planned = 'test' ~ ( $top-suite.planned   > 1 ?? 's' !! q{} );
        my $ran     = 'test' ~ ( $top-suite.tests-run > 1 ?? 's' !! q{} );
        return Status.new(
            exit-code => 255,
            error     => "planned {$top-suite.planned} $planned but ran {$top-suite.tests-run} $ran",
        );
    }
    elsif $unfinished-suites {
        my $unfinished = 'suite' ~ ( $unfinished-suites > 1 ?? 's' !! q{} );
        return Status.new(
            exit-code => 1,
            error     => "finalize was called but {@!suites.elems} $unfinished are still in process",
        );
    }

    return Status.new(
        exit-code => 0,
        error     => q{},
    );
}

method !end-current-suite {
    my $suite = @!suites.pop;
    @!finished-suites.unshift($suite);

    unless $suite.said-plan {
        self!say-plan( $suite.test-num );
        $suite.said-plan = True;
    }

    my $now = now;
    self!say-comment(
        $.output,
        "Started at {$suite.started-at.Rat}"
        ~ " - ended at {$now.Rat}"
        ~ " - elapsed time is {$now - $suite.started-at}s"
    );
}

method !die-unless-suites (Test::Stream::Event:D $event) {
    return if @!suites.elems;
    die "Received a {$event.type} event but there are no suites currently in progress";
}

method !current-suite {
    return @!suites[*-1];
}

method !say-plan (Int:D $count, Str $skip?) {
    my $plan-line = '1..' ~ $count;
    if $skip.defined {
        $plan-line ~= " # Skipped: $skip";
    }
    self!say-indented( $.output, $plan-line );
}

method !say-test-status (
    Bool:D :$ok,
    PositiveInt:D :$number,
    Str :$name?,
    Str :$todo-reason?,
    Str :$skip-reason?,
    Test::Stream::Diagnostic :$diagnostic?,
) {
    my $status-line = ( !$ok ?? q{not } !! q{} ) ~ "ok $number";

    if $name.defined {
        $status-line ~= q{ - } ~ escape($name);
    }

    if $todo-reason.defined {
        $status-line ~= q{ # TODO } ~ escape($todo-reason);
    }
    elsif $skip-reason.defined {
        $status-line ~= q{ # skip } ~ escape($skip-reason);
    }

    self!say-indented( $.output, $status-line );
    return if $ok && !$todo-reason.defined;
    self!maybe-say-diagnostic( $diagnostic, $todo-reason.defined );
}

method !maybe-say-diagnostic (Test::Stream::Diagnostic $diagnostic, Bool:D $is-todo)  {
    return unless $diagnostic.defined;

    my $output =
        $is-todo
        ?? $.todo-output
        !! $diagnostic.severity eq 'failure'
        ?? $.failure-output
        !! $.output;

    self!say-comment( $output, $diagnostic.message )
        if $diagnostic.message.defined;

    if $diagnostic.more.defined {
        if $diagnostic.more<got>.defined && $diagnostic.more<expected>.defined {
            self!say-comment( $output, q{    expected : } ~ $diagnostic.more<expected>.perl );
            self!say-comment( $output, q{    operator : } ~ $diagnostic.more<operator>.gist )
                if $diagnostic.more<operator>.defined;
            self!say-comment( $output, q{         got : } ~ $diagnostic.more<got>.perl )
        }
        else {
            for $diagnostic.more.keys.sort -> $k {
                self!say-comment( $output, qq[    $k : {$diagnostic.more{$k}.perl}] );
            }
        }
    }
}

method !say-comment (IO::Handle $output, Str:D $comment) {
    self!say-indented(
        $output,
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
    return @!suites.elems - 1;
}
