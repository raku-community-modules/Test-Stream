use v6;

unit module Test::Predicates;

use Test::Stream::Hub;
use Test::Predicator;

sub plan (|c) is export {
    instance().plan(|c);
}

sub pass (|c --> Bool:D) is export {
    return instance().pass(|c);
}

sub flunk (|c --> Bool:D) is export {
    return instance().flunk(|c);
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

sub isa-ok (|c --> Bool:D)  is export {
    return instance().isa-ok(|c);
}

sub does-ok (|c --> Bool:D)  is export {
    return instance().does-ok(|c);
}

sub can-ok (|c --> Bool:D)  is export {
    return instance().can-ok(|c);
}

sub like (|c --> Bool:D)  is export {
    return instance().like(|c);
}

sub unlike (|c --> Bool:D)  is export {
    return instance().unlike(|c);
}

sub is-deeply (|c --> Bool:D)  is export {
    return instance().is-deeply(|c);
}

# We need to repeat the signature from Test::Predicator here so that the
# compiler knows how to parse { } blocks passed to these subs.
sub subtest (Str:D $reason, &block --> Bool:D) is export {
    return instance().subtest( $reason, &block );
}

sub todo (Str:D $reason, &block) is export {
    instance().todo( $reason, &block );
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

sub skip-all (|c) is export {
    instance().skip-all(|c);
}

sub diag (|c) is export {
    instance().diag(|c);
}

my Test::Predicator $instance;
sub instance {
    return $instance //= Test::Predicator.new(
        hub => Test::Stream::Hub.instance,
    );
}

# In case it's not obvious this method is only for testing of Test::Stream. If
# you call it anywhere else you will probably break something. You have been
# warned.
our sub clear-instance-violently-for-test-stream-tests {
    $instance = (Test::Predicator);
}
