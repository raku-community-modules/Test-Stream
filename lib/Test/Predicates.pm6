use v6;

unit module Test::Predicates;

use Test::Stream::Formatter::TAP12;
use Test::Stream::Hub;
use Test::Predicator;

sub plan (|c) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    instance().plan(|c);
}

sub pass (|c --> Bool:D) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().pass(|c);
}

sub flunk (|c --> Bool:D) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().flunk(|c);
}

sub ok (|c --> Bool:D) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().ok(|c);
}

sub is (|c --> Bool:D)  is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().is(|c);
}

sub isnt (|c --> Bool:D)  is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().isnt(|c);
}

sub cmp-ok (|c --> Bool:D)  is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().cmp-ok(|c);
}

sub isa-ok (|c --> Bool:D)  is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().isa-ok(|c);
}

sub does-ok (|c --> Bool:D)  is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().does-ok(|c);
}

sub can-ok (|c --> Bool:D)  is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().can-ok(|c);
}

sub like (|c --> Bool:D)  is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().like(|c);
}

sub unlike (|c --> Bool:D)  is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().unlike(|c);
}

sub is-deeply (|c --> Bool:D)  is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().is-deeply(|c);
}

sub lives-ok (&block, $name? --> Bool:D) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().lives-ok( &block, $name );
}

sub dies-ok (&block, $name? --> Bool:D) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().dies-ok( &block, $name );
}

multi sub throws-like (&block, Mu:U $type, $name? --> Bool:D) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().throws-like( &block, $type, $name );
}

multi sub throws-like (&block, Regex:D $regex, $name? --> Bool:D) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().throws-like( &block, $regex, $name );
}

# We need to repeat the signature from Test::Predicator here so that the
# compiler knows how to parse { } blocks passed to these subs.
sub subtest (Str:D $reason, &block --> Bool:D) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    return instance().subtest( $reason, &block );
}

sub todo (Str:D $reason, &block) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    instance().todo( $reason, &block );
}

multi sub skip () is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    instance().skip( :count(1) );
}

multi sub skip ($reason, $count = 1) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    instance().skip(
        reason => $reason // (Str),
        :$count,
    );
}

sub skip-all (|c) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    instance().skip-all(|c);
}

sub diag (|c) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    instance().diag(|c);
}

sub bail (|c) is export {
    my $hub = Test::Stream::Hub.instance;
    $hub.set-context;
    LEAVE { $hub.release-context }
    instance().bail(|c);
    exit(255);
}

sub done-testing is export {
    my $status = instance().done-testing;
    if $status.error {
        say '# ' ~ Test::Stream::Formatter::TAP12::escape( $status.error );
    }
    exit( $status.exit-code );
}

my Test::Predicator $instance;
sub instance {
    unless $instance {
        my $hub = Test::Stream::Hub.instance;
        $hub.add-listener( Test::Stream::Formatter::TAP12.new )
            unless $hub.has-listeners;
        $instance = Test::Predicator.new( hub => $hub );
    }
    return $instance;
}

# In case it's not obvious this method is only for testing of Test::Stream. If
# you call it anywhere else you will probably break something. You have been
# warned.
our sub clear-instance-violently-for-test-stream-tests {
    $instance = (Test::Predicator);
}
