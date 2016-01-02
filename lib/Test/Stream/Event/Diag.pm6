use v6;

use Test::Stream::Event;

unit class Test::Stream::Event::Diag does Test::Stream::Event;

has Str:D $.message;
