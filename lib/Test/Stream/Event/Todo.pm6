use v6;

use Test::Stream::Event;

unit class Test::Stream::Event::Todo does Test::Stream::Event;

has Int:D $.tests;
has Str:D $.reason;
