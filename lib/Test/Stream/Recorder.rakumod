use Test::Stream::Listener;

unit class Test::Stream::Recorder does Test::Stream::Listener;

use Test::Stream::Event;

has @.events;

multi method accept-event (Test::Stream::Event::Bail:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::Diag:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::Note:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::Plan:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::Skip:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::SkipAll:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::Suite::Start:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::Suite::End:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::Test:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::Todo::Start:D $event) { @.events.append($event) }
multi method accept-event (Test::Stream::Event::Todo::End:D $event) { @.events.append($event) }

method clear { @.events = () }

# vim: expandtab shiftwidth=4
