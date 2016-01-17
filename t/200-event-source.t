use v6;
use lib 'lib', 't/lib';

use My::Test;
use Test::Stream::EventSource;
use Test::Stream::Hub;

my $hub = Test::Stream::Hub.instance;

my-subtest 'source marker stack', {
    my sub foo {
        $hub.set-context;
        LEAVE { $hub.release-context }
        return $hub.make-source
    }

    my sub bar {
        $hub.set-context;
        LEAVE { $hub.release-context }
        return foo();
    }

    my sub baz {
        return bar();
    }

    my-subtest 'sub returns source directly', {
        my $source = foo();
        if my-ok( $source.frame, 'source returned has a frame' ) {
            my-is( $source.file, $*PROGRAM-NAME, 'source points to this file' );
            my-is( $source.line, 28, 'source points to where a sub that sets a context is called' );
        }
    };

    my-subtest 'sub sets source marker and then calls another sub to make the source', {
        my $source = bar();
        if my-ok( $source.frame, 'source returned has a frame' ) {
            my-is( $source.file, $*PROGRAM-NAME, 'source points to this file' );
            my-is( $source.line, 36, 'source points to where a sub that sets a context is called' );
        }
    };

    my-subtest 'sub does not set source marker and then calls sub that does', {
        my $source = baz();
        if my-ok( $source.frame, 'source returned has a frame' ) {
            my-is( $source.file, $*PROGRAM-NAME, 'source points to this file' );
            my-is( $source.line, 23, 'source points to the line in a sub that does not set a context' );
        }
    };

    
};

my-done-testing;
