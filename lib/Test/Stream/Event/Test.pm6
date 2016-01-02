use v6;

use Test::Stream::Event::PassFail;

unit class Test::Stream::Event::Test does Test::Stream::Event::PassFail;

has Str:D @.diagnostics;
