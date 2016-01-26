use v6;

unit class Test::Stream::FinalStatus;

has Int:D $.exit-code = 0;
has Str:D $.error     = q{};

