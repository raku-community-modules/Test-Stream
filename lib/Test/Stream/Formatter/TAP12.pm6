use v6;

use Test::Stream::Listener;

unit class Test::Stream::Formatter::TAP12 does Test::Stream::Listener;

use Test::Stream::Diagnostic;
use Test::Stream::Types;

my class Suite {
    has Instant $.started-at;
    has Str $.name;
    has Int $.planned is rw;
    has Int:D $.tests-run is rw = 0;
    # This is the _real_ count because TODO tests are printed as "not ok" but
    # they don't count as actual failures.
    has Int:D $.real-failure-count is rw = 0;
    has Bool:D $.said-plan is rw = False;
    has Str $.todo-reason is rw;

    submethod BUILD (
        Instant:D :$!started-at,
        Str:D :$!name,
        Int :$!planned?,
    ) { }

    method next-test-number (--> PositiveInt:D) {
        return ++$.tests-run;
    }

    method in-todo (--> Bool:D) {
        return $.todo-reason.defined;
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
has Bool:D $.bailed is rw = False;
has Str $.bailed-reason is rw = (Str);

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
        die qq[Received a Suite::End event named "{$event.name}"]
          ~ qq[ but the most recent suite is named "{self!current-suite.name}"];
    }

    self!end-current-suite;
}

multi method accept-event (Test::Stream::Event::Plan:D $event) {
    self!die-unless-suites($event);

    self!say-plan( $event.planned );
}

multi method accept-event (Test::Stream::Event::SkipAll:D $event) {
    self!die-unless-suites($event);

    if self!current-suite.tests-run > 0 {
        my $ran = maybe-plural( self!current-suite.tests-run, 'test' );
        die "Received a SkipAll event but the current suite has already run {self!current-suite.tests-run} $ran";
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

multi method accept-event (Test::Stream::Event::Note:D $event) {
    self!die-unless-suites($event);
    self!say-comment( $.output, $event.message );
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
    $bail ~= qq[  {$event.reason}] if $event.reason;
    # This should never be indented.
    self.output.say($bail);

    $.bailed = True;
    $.bailed-reason = $event.reason;
}

multi method accept-event (Test::Stream::Event::Todo::Start:D $event) {
    self!die-unless-suites($event);

    self!current-suite.todo-reason = $event.reason;
}

multi method accept-event (Test::Stream::Event::Todo::End:D $event) {
    self!die-unless-suites($event);

    unless self!current-suite.todo-reason {
        die qq[Received a Todo::End event with a reason of "{$event.reason}"]
            ~ ' but there is no corresponding Todo::Start event';
    }

    unless $event.reason eq self!current-suite.todo-reason {
        die qq[Received a Todo::End event with a reason of "{$event.reason}" but the]
          ~ qq[ most recent Todo::Start reason was "{self!current-suite.todo-reason}"];
    }

    self!current-suite.todo-reason = (Str);
}

class Status {
    has Int:D $.exit-code = 0;
    has Str:D $.error     = q{};
}

method finalize (--> Status:D) {
    my $unfinished-suites = @!suites.elems;
    self!end-current-suite while @!suites;

    my $top-suite = @!finished-suites[0];

    # The exit-code is going to be used as an actual process exit code so it
    # cannot be greater than 254.

    if $.bailed {
        return Status.new(
            exit-code => 255,
            error     => 'Bailed out' ~ ( $.bailed-reason ?? qq{ - $.bailed-reason} !! q{} ),
        );
    }
    elsif $top-suite.real-failure-count > 0 {
        my $failed = maybe-plural( $top-suite.real-failure-count, 'test' );
        my $error = "failed {$top-suite.real-failure-count} $failed";
        return Status.new(
            exit-code => min( 254, $top-suite.real-failure-count ),
            error     => $error,
        );

    }
    elsif $top-suite.planned
          && ( $top-suite.planned != $top-suite.tests-run ) {

        my $planned = maybe-plural( $top-suite.planned, 'test' );
        my $ran     = maybe-plural( $top-suite.tests-run, 'test' );
        return Status.new(
            exit-code => 255,
            error     => "planned {$top-suite.planned} $planned but ran {$top-suite.tests-run} $ran",
        );
    }
    elsif $unfinished-suites {
        my $unfinished = maybe-plural( $unfinished-suites, 'suite' );
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
    my $suite = @!suites[*-1];
    unless $suite.said-plan {
        self!say-plan( $suite.tests-run );
    }

    if $suite.real-failure-count {
        my $failed = maybe-plural( $suite.real-failure-count, 'test' );
        self!say-comment(
            $.failure-output,
            "Looks like you failed {$suite.real-failure-count} $failed out of {$suite.tests-run}.",
        );
    }

    @!finished-suites.unshift(@!suites.pop);

    # With TAP, subtests get summarized as a single pass/fail in the
    # containing test suite.
    if @!suites.elems {
        self.accept-event(
            Test::Stream::Event::Test.new(
                passed => $suite.real-failure-count == 0,
                name   => $suite.name,
            )
        );
    }

    # It might be nice to add some timing output here as well, but for now
    # we'll stick with emulating Perl 5 as closely as possible.
}

method !die-unless-suites (Test::Stream::Event:D $event) {
    return if @!suites.elems;
    die "Received a {$event.type} event but there are no suites currently in progress";
}

method !current-suite {
    return @!suites[*-1];
}

method !say-plan (Int:D $planned, Str $skip?) {
    self!current-suite.planned = $planned;
    self!current-suite.said-plan = True;

    my $plan-line = '1..' ~ $planned;
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
    return ( @!suites.elems - 1 ) * 4;
}

# We know that that the nouns we're dealing with are all simple "add an 's'"
# nouns for pluralization.
sub maybe-plural (Int:D $count, Str:D $noun) {
    return $count > 1 ?? $noun ~ 's' !! $noun;
}
