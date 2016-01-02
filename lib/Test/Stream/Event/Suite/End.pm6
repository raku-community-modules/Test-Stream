use v6;

use Test::Stream::Event::PassFail;
use Test::Stream::Event::Suite;

unit class Test::Stream::Event::Subtest::Start
    does Test::Stream::Event::Suite
    does Test::Stream::Event::PassFail;
