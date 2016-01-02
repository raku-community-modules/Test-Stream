use v6;

use Test::Stream::Event;

unit class Test::Stream::Event::PassFail does Test::Stream::Event;

has Bool:D $.passed;
has Str:D $.name;
