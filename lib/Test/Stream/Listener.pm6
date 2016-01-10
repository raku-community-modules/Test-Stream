use v6;

use Test::Stream::Event;

role Test::Stream::Listener {
    multi method accept-event (Test::Stream::Event::Bail:D $event) { ... }
    multi method accept-event (Test::Stream::Event::Diag:D $event) { ... }
    multi method accept-event (Test::Stream::Event::Note:D $event) { ... }
    multi method accept-event (Test::Stream::Event::Plan:D $event) { ... }
    multi method accept-event (Test::Stream::Event::Skip:D $event) { ... }
    multi method accept-event (Test::Stream::Event::SkipAll:D $event) { ... }
    multi method accept-event (Test::Stream::Event::Test:D $event) { ... }
    multi method accept-event (Test::Stream::Event::Todo::Start:D $event) { ... }
    multi method accept-event (Test::Stream::Event::Todo::End:D $event) { ... }
    multi method accept-event (Test::Stream::Event::Suite::Start:D $event) { ... }
    multi method accept-event (Test::Stream::Event::Suite::End:D $event) { ... }
}

role Test::Stream::Listener::MostlyIgnores does Test::Stream::Listener {
    multi method accept-event (Test::Stream::Event::Bail:D $event) { }
    multi method accept-event (Test::Stream::Event::Diag:D $event) { }
    multi method accept-event (Test::Stream::Event::Note:D $event) { }
    multi method accept-event (Test::Stream::Event::Plan:D $event) { }
    multi method accept-event (Test::Stream::Event::Skip:D $event) { }
    multi method accept-event (Test::Stream::Event::SkipAll:D $event) { }
    multi method accept-event (Test::Stream::Event::Suite::Start:D $event) { }
    multi method accept-event (Test::Stream::Event::Suite::End:D $event) { }
    multi method accept-event (Test::Stream::Event::Test:D $event) { }
    multi method accept-event (Test::Stream::Event::Todo::Start:D $event) { }
    multi method accept-event (Test::Stream::Event::Todo::End:D $event) { }
}
