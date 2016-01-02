use v6;

unit role Test::Stream::Event;

use Test::Stream::EventSource;

has Test::Stream::EventSource $.source;

has Instant:D $.time;

method name {
    return self.^name.split(rx{'::'})[*-1];
}
