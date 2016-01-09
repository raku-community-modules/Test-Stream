use v6;
use lib 'lib', 't/lib';

use My::Listener;
use My::TAP;
use Test::Stream::Event;
use Test::Stream::Hub;

say "1..9";

my $hub = Test::Stream::Hub.instance;

my $l1 = My::Listener.new;
my $l2 = My::Listener.new;
$hub.add-listener($l1);
$hub.add-listener($l2);

$hub.send-event( Test::Stream::Event::Suite::Start.new( name => 'suite' ) );

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

$hub.send-event( Test::Stream::Event::Diag.new( message => 'blah' ) );

my-ok(
    $l1.events.elems == 2,
    'first listener got 2 events',
    $l1.events.elems
);
my-ok(
    $l2.events.elems == 2,
    'second listener got 2 events',
    $l2.events.elems
);

for ('Suite::Start', 'Diag').kv -> $i, $type {
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

my-ok(
    $hub eq Test::Stream::Hub.instance,
    'instance always returns the same object'
);
