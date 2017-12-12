use v6;
use lib 'lib', 't/lib';

use My::Test;
use Test::Predicator;
use Test::Stream::Hub;
use Test::Stream::IPC::Receiver;
use Test::Stream::IPC::Sender;

my %hubs;
my %recorders;
for ^5 -> $n {
    my $recorder = Test::Stream::Recorder.new;
    my $hub = Test::Stream::Hub.new;
    $hub.add-listener($recorder);

    %hubs{$n} = $hub;
    %recorders{$n} = $recorder;
}

my $port = 8987;
my $listen = IO::Socket::INET.new(
    :listen,
    localport => $port,
);

my $receiver = Test::Stream::IPC::Receiver.new(
    socket => $listen,
    hubs   => %hubs,
);

my @threads = gather {
    for ^5 -> $n {
        take Thread.start(
            name => "Test $n",
            sub {
                my $sender = Test::Stream::IPC::Sender.new( port => $port );
                my $hub = Test::Stream::Hub.new( event-tag => $n );
                $hub.add-listener($sender);
                run-tests( $hub, "Suite $n" );
            }
        );
    }
};

$receiver.listen;

.finish for @threads;

for %recorders.values -> $r {
    dd $r.events;
}

sub run-tests (Test::Stream::Hub:D $hub, Str:D $name) {
    $hub.set-context;
    LEAVE { $hub.release-context; }

    my $p = Test::Predicator.new(
        hub            => $hub,
        top-suite-name => $name,
    );

    $p.is( 42, 42, '42 is 42' );
    $p.subtest(
        "Subtest in $name",
        sub {
            $p.ok( True, 'thing 1' );
            $p.ok( False, 'thing 2' );
        },
    );
    $p.done-testing;
}
