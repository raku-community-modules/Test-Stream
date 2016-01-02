use v6;

use Test::Stream::Event;

unit class Test::Stream::Event::Bail does Test::Stream::Event;

has Str:D $.reason;
