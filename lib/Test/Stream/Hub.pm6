use v6;

unit class Test::Stream::Hub;

use Test::Stream::FinalStatus;
use Test::Stream::Listener;
use Test::Stream::Suite;
use Test::Stream::Util;

has $.event-tag;
has Test::Stream::Listener:D @.listeners;
# This is the current suite stack. We push and pop onto this as we go.
has Test::Stream::Suite:D @!suites;
# As we pop suites off @!suites we unshift them onto this so we always have
# access to them.
has Test::Stream::Suite:D @!finished-suites;
has CallFrame:D @!context;
has Bool:D $.is-finalized = False;

# My current thinking is that there should really just be one Hub per process
# in most scenarios. Different event producers and listeners can all attach to
# the one hub.
{
    my Test::Stream::Hub $instance;
    method instance ($class: |c) {
        return $instance //= $class.new(|c);
    }

    # In case it's not obvious this method is only for testing of
    # Test::Stream. If you call it anywhere else you will probably break
    # something. You have been warned.
    method clear-instance-violently-for-test-stream-tests {
        $instance = (Test::Stream::Hub);
    }
}

method add-listener (Test::Stream::Listener:D $listener) {
    @.listeners.append($listener);
}

method remove-listener (Test::Stream::Listener:D $listener) {
    @.listeners = @.listeners.grep( { $_ !=== $listener } );
}

method has-listeners (--> Bool:D) {
    return ?@.listeners;
}

method start-suite (Str:D :$name) {
    self.send-event(
        Test::Stream::Event::Suite::Start.new(
            name => $name,
        )
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
        Test::Stream::Event::Suite::End.new(
            name          => $name,
            tests-planned => $current.tests-planned,
            tests-run     => $current.tests-run,
            tests-failed  => $current.tests-failed,
            passed        => $current.passed,
        )
    );

    @!suites.pop;
    @!finished-suites.append($current);

    return $current;
}

method is-finished (--> Bool:D) {
    return ?( !@!suites || @!suites[0].bailed );
}

method main-suite (--> Test::Stream::Suite:D) {
    return @!suites[0];
}

method send-event (Test::Stream::Event:D $event) {
    unless @!context.elems || $event.source.defined {
        die "Attempted to send a {$event.^name} event before any context was set";
    }

    unless @.listeners.elems {
        die "Attempted to send a {$event.^name} event before any listeners were added";
    }

    dd $event if $event.source.defined;
    # It would probably be better to have some sort of property or role for
    # events that says they don't require suites.
    unless @!suites.elems
        || $event.isa(Test::Stream::Event::Suite::Start)
        || $event.isa(Test::Stream::Event::Finalize) {
        die "Attempted to send a {$event.^name} event before any suites were started";
    }

    # Same for here, except a property that says "can be sent after bail".
    if @!suites.elems && @!suites[0].bailed
        && !( $event.isa(Test::Stream::Event::Suite::End) || $event.isa(Test::Stream::Event::Finalize) ) {
        die "Attempted to send a {$event.^name} event after sending a Bail";
    }

    $event.set-source( self.make-source ) unless $event.source.defined;
    $event.set-event-tag($!event-tag) if $!event-tag.defined;

    .accept-event($event) for @.listeners;
}

method set-context {
    @!context.append( callframe(2) );
}

method release-context {
    @!context.pop;
}

method make-source {
    return Test::Stream::EventSource.from-frame( @!context[0] );
}

method finalize (--> Test::Stream::FinalStatus:D) {
    my $unfinished-suites = @!suites.elems;
    self.end-suite( name => $_.name ) for @!suites.reverse;

    my $status = self!final-status($unfinished-suites);

    self.send-event(
        Test::Stream::Event::Finalize.new(
            status => $status,
            source => self.make-source,
        ),
    );

    $!is-finalized = True;

    return $status;
}

method !final-status (Int:D $unfinished-suites --> Test::Stream::FinalStatus:D) {
    my $top-suite = @!finished-suites[0];

    # The exit-code is going to be used as an actual process exit code so it
    # cannot be greater than 254.
    if $top-suite.bailed {
        return Test::Stream::FinalStatus.new(
            exit-code => 255,
            error     =>
                'Bailed out'
                ~ ( $top-suite.bail-reason.defined ?? qq[ - {$top-suite.bail-reason}] !! q{} ),
        );
    }
    elsif $top-suite.tests-failed {
        my $failed = maybe-plural( $top-suite.tests-failed, 'test' );
        my $error = "failed {$top-suite.tests-failed} $failed";
        return Test::Stream::FinalStatus.new(
            exit-code => min( 254, $top-suite.tests-failed ),
            error     => $error,
        );
    }
    elsif $top-suite.tests-planned
       && ( $top-suite.tests-planned != $top-suite.tests-run ) {

        my $planned = maybe-plural( $top-suite.tests-planned, 'test' );
        my $ran     = maybe-plural( $top-suite.tests-run, 'test' );
        return Test::Stream::FinalStatus.new(
            exit-code => 255,
            error     => "planned {$top-suite.tests-planned} $planned but ran {$top-suite.tests-run} $ran",
        );
    }
    elsif $unfinished-suites {
        my $unfinished = maybe-plural( $unfinished-suites, 'suite' );
        return Test::Stream::FinalStatus.new(
            exit-code => 1,
            error     => "finalize was called but {$unfinished-suites} $unfinished are still in process",
        );
    }

    return Test::Stream::FinalStatus.new(
        exit-code => 0,
        error     => q{},
    );
}
