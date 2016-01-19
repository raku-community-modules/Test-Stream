use v6;

unit class Test::Stream::Hub;

use Test::Stream::Listener;
use Test::Stream::Suite;
use Test::Stream::Util;

has Test::Stream::Listener:D @.listeners;
# This is the current suite stack. We push and pop onto this as we go.
has Test::Stream::Suite:D @!suites;
# As we pop suites off @!suites we unshift them onto this so we always have
# access to them.
has Test::Stream::Suite:D @!finished-suites;
has CallFrame:D @!context;

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

method main-suite (--> Test::Stream::Suite:D) {
    return @!suites[0];
}

method send-event (Test::Stream::Event:D $event) {
    unless @!context.elems {
        die "Attempted to send a {$event.^name} event before any context was set";
    }

    unless @.listeners.elems {
        die "Attempted to send a {$event.^name} event before any listeners were added";
    }

    unless @!suites.elems || $event.isa(Test::Stream::Event::Suite::Start) {
        die "Attempted to send a {$event.^name} event before any suites were started";
    }

    if @!suites.elems && @!suites[0].bailed && !$event.isa(Test::Stream::Event::Suite::End) {
        die "Attempted to send a {$event.^name} event after sending a Bail";
    }

    $event.set-source( self.make-source );
    .accept-event($event) for @.listeners;
}

method set-context {
    @!context.append( callframe(2) );
}

method release-context {
    @!context.pop;
}

method make-source {
    return Test::Stream::EventSource.new( :frame( @!context[0] ) );
}

class Status {
    has Int:D $.exit-code = 0;
    has Str:D $.error     = q{};
}

method finalize (--> Status:D) {
    my $unfinished-suites = @!suites.elems;
    self.end-suite( name => $_.name ) for @!suites.reverse;

    my $top-suite = @!finished-suites[0];

    # The exit-code is going to be used as an actual process exit code so it
    # cannot be greater than 254.
    if $top-suite.bailed {
        return Status.new(
            exit-code => 255,
            error     =>
                'Bailed out'
                ~ ( $top-suite.bail-reason.defined ?? qq[ - {$top-suite.bail-reason}] !! q{} ),
        );
    }
    elsif $top-suite.tests-failed {
        my $failed = maybe-plural( $top-suite.tests-failed, 'test' );
        my $error = "failed {$top-suite.tests-failed} $failed";
        return Status.new(
            exit-code => min( 254, $top-suite.tests-failed ),
            error     => $error,
        );
    }
    elsif $top-suite.tests-planned
          && ( $top-suite.tests-planned != $top-suite.tests-run ) {

        my $planned = maybe-plural( $top-suite.tests-planned, 'test' );
        my $ran     = maybe-plural( $top-suite.tests-run, 'test' );
        return Status.new(
            exit-code => 255,
            error     => "planned {$top-suite.tests-planned} $planned but ran {$top-suite.tests-run} $ran",
        );
    }
    elsif $unfinished-suites {
        my $unfinished = maybe-plural( $unfinished-suites, 'suite' );
        return Status.new(
            exit-code => 1,
            error     => "finalize was called but {$unfinished-suites} $unfinished are still in process",
        );
    }

    return Status.new(
        exit-code => 0,
        error     => q{},
    );
}
