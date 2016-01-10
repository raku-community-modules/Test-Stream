use v6;

unit class Test::Stream::Hub;

use Test::Stream::Listener;
use Test::Stream::Suite;

has Test::Stream::Listener @.listeners;
# This is the current suite stack. We push and pop onto this as we go.
has Test::Stream::Suite @!suites;
# As we pop suites off @!suites we unshift them onto this so we always have
# access to them.
has Test::Stream::Suite @!finished-suites;

# My current thinking is that there should really just be one Hub per process
# in most scenarios. Different event producers and listeners can all attach to
# the one hub.
method instance ($class: |c) {
    return state $instance //= $class.new(|c);
}

method add-listener (Test::Stream::Listener:D $listener) {
    @.listeners.append($listener);
}

method remove-listener (Test::Stream::Listener:D $listener) {
    @.listeners = @.listeners.grep( { $_ !=== $listener } );
}

method start-suite (Str:D :$name) {
    self.send-event(
        Test::Stream::Event::Suite::Start,
        name => $name,
    );

    my $suite = Test::Stream::Suite.new( name => $name );
    self.add-listener($suite);
    @!suites.append($suite);
}

method end-suite (Str:D :$name) {
    die "Attempted to end a suite ($name) before any suites were started"
        unless @!suites.elems;

    my $current = @!suites[*-1];
    die "Attempted to end a suite ($name) that is not the currently running suite ({$current.name})"
        unless $current.name eq $name;

    self.remove-listener($current);

    self.send-event(
        Test::Stream::Event::Suite::End,
        name          => $name,
        tests-planned => $current.tests-planned,
        tests-run     => $current.tests-run,
        tests-failed  => $current.tests-failed,
        passed        => $current.passed,
    );

    @!suites.pop;
    @!finished-suites.append($current);

    return $current;
}

method send-event (Test::Stream::Event:U $class, *%args) {
    unless self!in-a-suite || $class === Test::Stream::Event::Suite::Start {
        die "Attempted to send a {$class.^name} event before any suites were started";
    }

    %args<source> //= Test::Stream::EventSource.new;
    my $event = $class.new(|%args);
    .accept-event($event) for @.listeners;
}

method !in-a-suite (--> Bool:D) {
    return ?@!suites.elems;
}
