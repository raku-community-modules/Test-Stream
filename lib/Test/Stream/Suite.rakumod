use Test::Stream::Listener;

# This class is injected into the hub while we run a suite. We track some of
# the events that the suite produces in order to determine whether or not the
# suite itself passed. This is important for TAP and possibly other formats,
# and makes it much easier to generate proper Suite::End events.
#
# It also tracks further suite events so that it can ignore nested suites and
# only increment the tests-run count by 1 for the whole nested suite, rather
# than once for each test that a nested suite runs.
unit class Test::Stream::Suite does Test::Stream::Listener::MostlyIgnores;

use Test::Stream::Event;
use Test::Stream::Util;

has Str    $.name;
has Int    $.tests-planned;
has Int:D  $.tests-run     = 0;
has Int:D  $.tests-failed  = 0;
has Bool:D $.bailed        = False;
has Str    $.bail-reason;
has Str    @!todo-reasons;
has Int:D  $!subtest-depth = 0;

submethod BUILD (Str:D :$!name) { }

multi method accept-event (Test::Stream::Event::Plan:D $event) {
    return if $!subtest-depth;
    $!tests-planned = $event.planned;
}

multi method accept-event (Test::Stream::Event::Test:D $event) {
    return if $!subtest-depth;
    $!tests-run++;
    return if @!todo-reasons.elems;
    $!tests-failed++ unless $event.passed;
}

multi method accept-event (Test::Stream::Event::Todo::Start:D $event) {
    return if $!subtest-depth;
    @!todo-reasons.append( $event.reason );
}
multi method accept-event (Test::Stream::Event::Todo::End:D $event) {
    return if $!subtest-depth;

    unless @!todo-reasons.elems {
        die qq[Received a Todo::End event with a reason of "{$event.reason}"]
            ~ ' but there is no corresponding Todo::Start event';
    }

    unless $event.reason eq @!todo-reasons[*-1] {
        die qq[Received a Todo::End event with a reason of "{$event.reason}"]
          ~ qq[ but the most recent Todo::Start reason was "{@!todo-reasons[*-1]}"];
    }

    @!todo-reasons.pop;
}

multi method accept-event (Test::Stream::Event::Skip:D $event) {
    return if $!subtest-depth;
    $!tests-run += $event.count;
}

multi method accept-event (Test::Stream::Event::SkipAll:D $event) {
    return if $!subtest-depth;

    if $!tests-run {
        my $ran = maybe-plural( $!tests-run, 'test' );
        die "Received a SkipAll event but the current suite has already run {$!tests-run} $ran";
    }

    $!tests-planned = 0;
}

multi method accept-event (Test::Stream::Event::Bail:D $event) {
    $!bailed = True;
    $!bail-reason = $event.reason if $event.reason.defined;
}

multi method accept-event (Test::Stream::Event::Suite::Start:D $event) {
    $!subtest-depth++;
}
multi method accept-event (Test::Stream::Event::Suite::End:D $event) {
    if $!subtest-depth == 1 {
        $!tests-run++;
        $!tests-failed++ unless $event.passed;
    }
    $!subtest-depth--;
}

# Passed: plan was correct or plan was not called, 1+ tests were run or
# SkipAll was sent, and all tests passed or were todo tests
#
# ... or ...
#
# Failed: plan did not match actual number of tests, no tests were run, or at
# least 1 test failed.
method passed (--> Bool:D) {
    return False if $!tests-failed;
    return True if $!tests-run && !$!tests-planned.defined;
    # We want to allow a plan of 0 for SkipAll events
    return True if $!tests-planned.defined && $!tests-run == $!tests-planned;
    False
}

# vim: expandtab shiftwidth=4
