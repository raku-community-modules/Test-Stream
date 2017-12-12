use v6;

unit class Test::Stream::IPC::Receiver;

use Test::Stream::Event;
use Test::Stream::Hub;

has IO::Socket::INET $.socket;
has Test::Stream::Hub %.hubs;

method listen {
    loop {
        my $conn = $.socket.accept;
        while my $buf = $conn.recv(:bin) {
            my $event = self!buffer-to-event($buf);
            unless $event.event-tag.defined {
                die "Received a {$event.type} event without an event-tag";
            }

            self!send-to-correct-hub($event);

            return if all( %!hubs.values.map( *.is-finalized ) );
        }
    }
}

method !send-to-correct-hub (Test::Stream::Event:D $event) {
    my $hub = %!hubs{ $event.event-tag };
    die "Received an event with an unrecognized event-tag ({$event.event-tag})"
        unless $hub.defined;
    $hub.send-event($event);
}

my class X::Test::Stream::BadIPCBuffer is Exception {
    method message {
        'Received a buffer which does not EVAL to a Test::Stream::Event object';
    }
}

method !buffer-to-event (Buf:D $buffer --> Test::Stream::Event:D) {
    use MONKEY-SEE-NO-EVAL;
    my $event = EVAL( $buffer.decode );
    unless $event.defined && $event ~~ Test::Stream::Event {
        X::Test::Stream::BadIPCBuffer.throw(:$buffer);
    }
    return $event;
}
