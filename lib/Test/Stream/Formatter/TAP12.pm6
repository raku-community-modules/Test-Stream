use v6;

use Test::Stream::Listener;

unit class Test::Stream::Formatter::TAP12 does Test::Stream::Listener;

use Test::Stream::Diagnostic;
use Test::Stream::Types;

has IO::Handle $.output = $*OUT;
has IO::Handle $.todo-output = $*OUT;
has IO::Handle $.failure-output = $*ERR;
has Bool:D $.bailed is rw = False;
has Str $.bailed-reason is rw = (Str);
has Int:D $!suite-level = 0;
has Int:D @!test-number-stack = (0);
has Str $todo-reason;

multi method accept-event (Test::Stream::Event::Suite::Start:D $event) {
    # We want this comment to appear at the _current_ indentation level, not
    # indented for the subtest that we're starting.
    if $!suite-level > 0 {
        self!say-comment( $.output, q{Subtest } ~ $event.name );
    }

    $!suite-level++;
    @!test-number-stack.append(0);
}

multi method accept-event (Test::Stream::Event::Suite::End:D $event) {
    if $event.tests-planned.defined {
        unless $event.tests-planned == $event.tests-run {
            my $planned = maybe-plural( $event.tests-planned, 'test' );
            my $ran = maybe-plural( $event.tests-run, 'test' );
            self!say-comment(
                $.failure-output,
                "You planned {$event.tests-planned} $planned but ran {$event.tests-run} $ran.",
            );
        }
    }
    else {
        self!say-plan( $event.tests-run );
    }

    if $event.tests-failed {
        my $failed = maybe-plural( $event.tests-failed, 'test' );
        self!say-comment(
            $.failure-output,
            "Looks like you failed {$event.tests-failed} $failed out of {$event.tests-run}.",
        );
    }

    @!test-number-stack.pop;
    $!suite-level--;

    # With TAP, subtests get summarized as a single pass/fail in the
    # containing test suite.
    if $!suite-level {
        self!say-test-status(
            Test::Stream::Event::Test.new(
                passed => $event.passed,
                name   => $event.name,
            ),
            self!next-test-number,
            False,
        );
    }

    # It might be nice to add some timing output here as well, but for now
    # we'll stick with emulating Perl 5 as closely as possible.
}

multi method accept-event (Test::Stream::Event::Plan:D $event) {
    self!say-plan( $event.planned );
}

multi method accept-event (Test::Stream::Event::SkipAll:D $event) {
    # if self!current-suite.tests-run > 0 {
    #     my $ran = maybe-plural( self!current-suite.tests-run, 'test' );
    #     die "Received a SkipAll event but the current suite has already run {self!current-suite.tests-run} $ran";
    # }

    self!say-plan( 0, $event.reason );
}

multi method accept-event (Test::Stream::Event::Diag:D $event) {
    my $output =
        self!in-todo
        ?? $.todo-output
        !! $.failure-output;

    self!say-comment( $output, $event.message );
}

multi method accept-event (Test::Stream::Event::Note:D $event) {
    self!say-comment( $.output, $event.message );
}

multi method accept-event (Test::Stream::Event::Test:D $event) {
    self!say-test-status( $event, self!next-test-number );
}

multi method accept-event (Test::Stream::Event::Skip:D $event) {
    for 1..$event.count {
        self!say-test-status( $event, self!next-test-number );
    }
}

multi method accept-event (Test::Stream::Event::Bail:D $event) {
    my $bail = 'Bail out!';
    $bail ~= qq[  {$event.reason}] if $event.reason;
    # This should never be indented.
    self.output.say($bail);

    $.bailed = True;
    $.bailed-reason = $event.reason;
}

multi method accept-event (Test::Stream::Event::Todo::Start:D $event) {
    $!todo-reason = $event.reason;
}

method !in-todo { $!todo-reason.defined }

multi method accept-event (Test::Stream::Event::Todo::End:D $event) {
    unless $!todo-reason {
        die qq[Received a Todo::End event with a reason of "{$event.reason}"]
            ~ ' but there is no corresponding Todo::Start event';
    }

    unless $event.reason eq $!todo-reason {
        die qq[Received a Todo::End event with a reason of "{$event.reason}" but the]
          ~ qq[ most recent Todo::Start reason was "{$!todo-reason}"];
    }

    $!todo-reason = (Str);
}

method !say-plan (Int:D $planned, Str $skip?) {
    my $plan-line = '1..' ~ $planned;
    if $skip.defined {
        $plan-line ~= " # Skipped: $skip";
    }
    self!say-indented( $.output, $plan-line );
}

method !say-test-status (Test::Stream::Event:D $event, PositiveInt:D $number, Bool:D $diag-source = True) {
    my $ok = do given $event {
        when Test::Stream::Event::Skip {
            True;
        }
        default {
            $event.passed;
        }
    };

    my $status-line = ( !$ok ?? q{not } !! q{} ) ~ "ok $number";

    if $event.can('name') && $event.name.defined {
        $status-line ~= q{ - } ~ escape( $event.name );
    }

    if self!in-todo {
        $status-line ~= q{ # TODO } ~ escape( $!todo-reason );
    }
    elsif $event ~~ Test::Stream::Event::Skip && $event.reason.defined {
        $status-line ~= q{ # skip } ~ escape( $event.reason );
    }

    self!say-indented( $.output, $status-line );

    return if $ok;

    if $diag-source {
        my $fail-msg = q{  Failed};
        $fail-msg ~= q{ (TODO)} if self!in-todo;
        $fail-msg ~= q{ test};
        $fail-msg ~= qq[ '{$event.name}'] if $event.name.defined;
        my $at-msg = q{  at } ~ $event.source.file ~ q{ line } ~ $event.source.line;

        my $output =
            self!in-todo
            ?? $.todo-output
            !! $.failure-output;
        self!say-comment( $output, $_ )
            for ( $fail-msg, $at-msg );
    }

    self!maybe-say-diagnostic( $event.diagnostic );
}

method !next-test-number {
    return ++@!test-number-stack[*-1];
}

method !maybe-say-diagnostic (Test::Stream::Diagnostic $diagnostic)  {
    return unless $diagnostic.defined;

    my $output =
        self!in-todo
        ?? $.todo-output
        !! $diagnostic.severity eq 'failure'
        ?? $.failure-output
        !! $.output;

    self!say-comment( $output, $diagnostic.message )
        if $diagnostic.message.defined;

    if $diagnostic.more.defined {
        if $diagnostic.more<got>.defined && $diagnostic.more<expected>.defined {
            self!say-comment( $output, q{    expected : } ~ $diagnostic.more<expected>.perl );
            if $diagnostic.more<operator>.defined {
                my $op-str = do given $diagnostic.more<operator> {
                    when Str  {
                        $diagnostic.more<operator>;
                    }
                    when Callable {
                        $diagnostic.more<operator>.name ne q{}
                        ?? $diagnostic.more<operator>.name
                        !! $diagnostic.more<operator>.gist;
                    }
                    default {
                        $diagnostic.more<operator>.gist;
                    }
                };
                self!say-comment( $output, q{    operator : } ~ $op-str );
            }
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
    return ( $!suite-level - 1 ) * 4;
}

# We know that that the nouns we're dealing with are all simple "add an 's'"
# nouns for pluralization.
sub maybe-plural (Int:D $count, Str:D $noun) {
    return $count > 1 ?? $noun ~ 's' !! $noun;
}
