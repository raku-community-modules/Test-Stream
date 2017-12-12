use v6;

use Test::Stream::Listener;

unit class Test::Stream::IPC::Sender does Test::Stream::Listener::MostlyIgnores;

has Int $.port;

multi method accept-event (Test::Stream::Event::Bail:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Diag:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Note:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Plan:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Skip:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::SkipAll:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Suite::Start:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Suite::End:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Test:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Todo::Start:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Todo::End:D $event) { self!send-event($event) }
multi method accept-event (Test::Stream::Event::Finalize:D $event) { self!send-event($event) }

method !send-event (Test::Stream::Event:D $event) {
    my $socket = IO::Socket::INET.new(
        host => 'localhost',
        port => $!port,
    );
    $socket.write( $event.perl.encode );
    $socket.close;
}
