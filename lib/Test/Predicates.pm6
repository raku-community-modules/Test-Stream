use v6;

unit module Test::Predicates;

use Test::Stream::Hub;
use Test::Predicator;

sub plan (|c) is export {
    instance().plan(|c);
}

sub ok (|c --> Bool:D) is export {
    return instance().ok(|c);
}

sub is (|c --> Bool:D)  is export {
    return instance().is(|c);
}

sub isnt (|c --> Bool:D)  is export {
    return instance().isnt(|c);
}

sub cmp-ok (|c --> Bool:D)  is export {
    return instance().cmp-ok(|c);
}

sub subtest (Str:D $name, &block --> Bool:D) is export {
    return instance().subtest( $name, &block );
}

multi sub skip () is export {
    instance().skip( :count(1) );
}

multi sub skip ($reason, $count = 1) is export {
    instance().skip(
        reason => $reason // (Str),
        :$count,
    );
}

sub skip-all ($reason?) is export {
    instance().skip-all( $reason // (Str) );
}

sub diag (|c) is export {
    instance().diag(|c);
}

sub instance  {
    state $instance //= Test::Predicator.new(
        hub => Test::Stream::Hub.instance,
    );
}
