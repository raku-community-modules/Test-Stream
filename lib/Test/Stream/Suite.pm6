use v6;

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

has Str    $.name;
has Int    $.tests-planned;
has Int:D  $.tests-run     = 0;
has Int:D  $.tests-failed  = 0;
has Bool:D $!in-todo       = False;
has Int:D  $!subtest-depth = 0;

submethod BUILD (Str:D :$!name) { }

multi method accept-event (Test::Stream::Event::Plan:D $event) {
    return if $!subtest-depth;
    $!tests-planned = $event.planned;
}

multi method accept-event (Test::Stream::Event::Test:D $event) {
    $!tests-run++ unless $!subtest-depth;
    return if $!in-todo;
    $!tests-failed++ unless $event.passed;
}

multi method accept-event (Test::Stream::Event::Todo::Start:D $event) {
    return if $!subtest-depth;
    $!in-todo = True;
}
multi method accept-event (Test::Stream::Event::Todo::End:D $event) {
    return if $!subtest-depth;
    $!in-todo = False;
}

multi method accept-event (Test::Stream::Event::Skip:D $event) {
    return if $!subtest-depth;
    $!tests-run += $event.count;
}

multi method accept-event (Test::Stream::Event::Suite::Start:D $event) {
    $!subtest-depth++;
}
multi method accept-event (Test::Stream::Event::Suite::End:D $event) {
    $!tests-run++;
    $!tests-failed++ unless $event.passed;
    $!subtest-depth--;
}

# Passed: plan was correct or plan was not called, 1+ tests were run, and all
# tests passed or were todo tests
#
# ... or ...
#
# Failed: plan did not match actual number of tests, no tests were run, or at
# least 1 test failed.
method passed (--> Bool:D) {
    return
        ?( $!tests-failed == 0
           && $!tests-run
           && ( !$!tests-planned.defined || $!tests-run == $!tests-planned ) );
}
