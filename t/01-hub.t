use v6;
use lib 'lib', 't/lib';

use My::Listener;
use My::TAP;
use Test::Stream::Event;
use Test::Stream::Hub;

say "1..9";

{
    my $hub = Test::Stream::Hub.new;

    my $l1 = My::Listener.new;
    my $l2 = My::Listener.new;
    $hub.add-listener($l1);
    $hub.add-listener($l2);

    $hub.start-suite( name => 'suite' );

    my-ok(
        $l1.events.elems == 1,
        'first listener got 1 event',
        $l1.events.elems
    );
    my-ok(
        $l2.events.elems == 1,
        'second listener got 1 event',
        $l2.events.elems
    );

    $hub.send-event(
        Test::Stream::Event::Diag,
        message => 'blah',
    );

    $hub.end-suite( name => 'suite' );

    my-ok(
        $l1.events.elems == 3,
        'first listener got 3 events',
        $l1.events.elems
    );
    my-ok(
        $l2.events.elems == 3,
        'second listener got 3 events',
        $l2.events.elems
    );

    for < Suite::Start Diag Suite::End >.kv -> $i, $type {
        my-ok(
            $l1.events[$i].type eq $type,
            "first listener event #$i is a $type",
            $l1.events[$i].type,
        );
        my-ok(
            $l2.events[$i].type eq $type,
            "second listener event #$i is a $type",
            $l2.events[$i].type,
        );
    }

    $hub.remove-listener($l2);

    my-ok(
        $hub.listeners.elems == 1,
        'hub has one listener after calling remove-listener'
    );
    my-ok(
        $hub.listeners[0] === $l1,
        'the remaining listener is the one that was not removed'
    );
}

{
    my $hub = Test::Stream::Hub.new;
    my $l = My::Listener.new;

    $hub.add-listener($l);

    my $e = my-throws-ok(
        {
            $hub.send-event(
                Test::Stream::Event::Plan,
                planned => 42,
            )
        },
        'got exception trying to send a plan before starting a suite'
    );
    my-ok(
        $e.message ~~ rx{ 'Attempted to send a Test::Stream::Event::Plan event before any suites were started' },
        'got expected error'
    );

    $e = my-throws-ok(
        {
            $hub.end-suite( name => 'random-suite' );
        },
        'got exception trying to end a suite before any suites were started'
    );
    my-ok(
        $e.message ~~ rx{ 'Attempted to end a suite (random-suite) before any suites were started' },
        'got expected error'
    );

    $hub.start-suite( name => 'top' );
    test-event-stream(
        $l,
        ${
            class      => Test::Stream::Event::Suite::Start,
            attributes => ${
                name => 'top',
            },
        },
    );

    $hub.start-suite( name => 'depth 1' );
    test-event-stream(
        $l,
        ${
            class      => Test::Stream::Event::Suite::Start,
            attributes => ${
                name => 'depth 1',
            },
        },
    );

    $e = my-throws-ok(
        {
            $hub.end-suite( name => 'random-suite' );
        },
        'got exception trying to end a suite that does not match the last suite started (depth of 2)'
    );
    my-ok(
        $e.message ~~ rx{ 'Attempted to end a suite (random-suite) that is not the currently running suite (depth 1)' },
        'got expected error'
    );

    $hub.send-event(
        Test::Stream::Event::Test,
        passed => True,
    );
    test-event-stream(
        $l,
        ${
            class      => Test::Stream::Event::Test,
            attributes => ${
                passed => True,
            },
        },
    );

    $hub.end-suite( name => 'depth 1' );
    test-event-stream(
        $l,
        ${
            class      => Test::Stream::Event::Suite::End,
            attributes => ${
                name          => 'depth 1',
                tests-planned => (Int),
                tests-run     => 1,
                tests-failed  => 0,
                passed        => True,
            },
        },
    );

    $e = my-throws-ok(
        {
            $hub.end-suite( name => 'random-suite' );
        },
        'got exception trying to end a suite that does not match the last suite started (depth of 1)'
    );
    my-ok(
        $e.message ~~ rx{ 'Attempted to end a suite (random-suite) that is not the currently running suite (top)' },
        'got expected error'
    );

    $hub.end-suite( name => 'top' );
    test-event-stream(
        $l,
        ${
            class      => Test::Stream::Event::Suite::End,
            attributes => ${
                name          => 'top',
                tests-planned => (Int),
                tests-run     => 1,
                tests-failed  => 0,
                passed        => True,
            },
        },
    );
}

{
    my $hub = Test::Stream::Hub.instance;

    my-ok(
        $hub eq Test::Stream::Hub.instance,
        'instance always returns the same object'
    );
}
