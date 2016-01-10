use v6;

unit class Test::Stream::Hub;

use Test::Stream::Listener;

has Test::Stream::Listener @.listeners;

# My current thinking is that there should really just be one Hub per process
# in most scenarios. Different event producers and listeners can all attach to
# the one hub.
method instance ($class: |c) {
    return state $instance //= $class.new(|c);
}

method add-listener (Test::Stream::Listener:D $listener) {
    @.listeners.append($listener);
}

method remove-listener (Test::Stream::Listener:D $listener) {
    @.listeners = @.listeners.grep( { $_ !=== $listener } );
}

method send-event (Test::Stream::Event:D $event) {
    .accept-event($event) for @.listeners;
}
