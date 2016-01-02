use v6;

unit role Test::Stream::Listener;

use Test::Stream::Event;

multi method accept-event (Test::Stream::Event::Bail:D $event) { ... }
multi method accept-event (Test::Stream::Event::Diag:D $event) { ... }
multi method accept-event (Test::Stream::Event::Plan:D $event) { ... }
multi method accept-event (Test::Stream::Event::Skip:D $event) { ... }
multi method accept-event (Test::Stream::Event::SkipAll:D $event) { ... }
multi method accept-event (Test::Stream::Event::Suite::Start:D $event) { ... }
multi method accept-event (Test::Stream::Event::Suite::End:D $event) { ... }
multi method accept-event (Test::Stream::Event::Test:D $event) { ... }
multi method accept-event (Test::Stream::Event::Todo:D $event) { ... }


