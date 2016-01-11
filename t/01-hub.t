use v6;
use lib 'lib', 't/lib';

use My::Listener;
use My::Test;
use Test::Stream::Event;
use Test::Stream::Hub;

{
    my $hub = Test::Stream::Hub.new;

    my $l1 = My::Listener.new;
    my $l2 = My::Listener.new;
    $hub.add-listener($l1);
    $hub.add-listener($l2);

    $hub.start-suite( name => 'suite' );

    my-is(
        $l1.events.elems, 1,
        'first listener got 1 event',
    );
    my-is(
        $l2.events.elems, 1,
        'second listener got 1 event',
    );

    $hub.send-event(
        Test::Stream::Event::Diag.new(
            message => 'blah',
        )
    );

    $hub.end-suite( name => 'suite' );

    my-is(
        $l1.events.elems, 3,
        'first listener got 3 events',
    );
    my-is(
        $l2.events.elems, 3,
        'second listener got 3 events',
    );

    for < Suite::Start Diag Suite::End >.kv -> $i, $type {
        my-is(
            $l1.events[$i].type, $type,
            "first listener event #$i is a $type",
        );
        my-is(
            $l2.events[$i].type, $type,
            "second listener event #$i is a $type",
        );
    }

    $hub.remove-listener($l2);

    my-is(
        $hub.listeners.elems, 1,
        'hub has one listener after calling remove-listener'
    );
    my-is(
        $hub.listeners[0], $l1,
        'the remaining listener is the one that was not removed'
    );
}

{
    my $hub = Test::Stream::Hub.new;
    my $l = My::Listener.new;

    $hub.add-listener($l);

    my-throws-like(
        {
            $hub.send-event(
                Test::Stream::Event::Plan.new(
                    planned => 42,
                )
            )
        },
        rx{ 'Attempted to send a Test::Stream::Event::Plan event before any suites were started' },
        'got exception trying to send a plan before starting a suite'
    );

    my-throws-like(
        {
            $hub.end-suite( name => 'random-suite' );
        },
        rx{ 'Attempted to end a suite (random-suite) before any suites were started' },
        'got exception trying to end a suite before any suites were started'
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

    my-throws-like(
        {
            $hub.end-suite( name => 'random-suite' );
        },
        rx{ 'Attempted to end a suite (random-suite) that is not the currently running suite (depth 1)' },
        'got exception trying to end a suite that does not match the last suite started (depth of 2)'
    );

    $hub.send-event(
        Test::Stream::Event::Test.new(
            passed => True,
        )
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

    my-throws-like(
        {
            $hub.end-suite( name => 'random-suite' );
        },
        rx{ 'Attempted to end a suite (random-suite) that is not the currently running suite (top)' },
        'got exception trying to end a suite that does not match the last suite started (depth of 1)'
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
    my $hub = Test::Stream::Hub.new;
    my-throws-like(
        {
            $hub.start-suite( name => 'whatever' );
        },
        rx{ 'Attempted to send a Test::Stream::Event::Suite::Start event before any listeners were added' },
        'got exception trying to start a suite without any listeners added'
    );
}

{
    my $hub = Test::Stream::Hub.instance;

    my-is(
        $hub, Test::Stream::Hub.instance,
        'instance always returns the same object'
    );
}

my-done-testing;
