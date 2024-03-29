use v6;
use lib 'lib', 't/lib';

use My::Test;
use Test::Predicates;
use Test::Stream::Diagnostic;
use Test::Stream::Recorder;
use Test::Stream::Types;

{
    my $listener = listener();

    my-subtest 'plan(42)', {
        plan(42);
        test-event-stream(
            $listener,
            ${
                class      => Test::Stream::Event::Suite::Start,
                attributes => ${ name => '300-predicates.t' },
            },
            ${
                class  => Test::Stream::Event::Plan,
                attributes => ${
                    planned => 42,
                },
            },
        );
    };

    my-subtest 'ok(True) without name', {
        my-is( ok(True), True, 'ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
        );
    };

    my-subtest 'ok(False) without name', {
        my-is( ok(False), False, 'ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            }
        );
    };

    my-subtest 'ok(True) with name', {
        my-is( ok( True, 'is true' ), True, 'ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => 'is true',
                    diagnostic => (Test::Stream::Diagnostic)
                },
            }
        );
    };

    my-subtest 'ok(False) with name', {
        my-is( ok( False, 'is false' ), False, 'ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => 'is false',
                    diagnostic => (Test::Stream::Diagnostic)
                },
            }
        );
    };

    my-subtest 'ok(1) without name', {
        my-is( ok(1), True, 'ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
        );
    };

    my-subtest 'ok(0) without name', {
        my-is( ok(0), False, 'ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
        );
    };

    my-subtest 'pass()', {
        my-is( pass(), True, 'pass returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
        );
    };

    my-subtest 'flunk()', {
        my-is( flunk(), False, 'flunk returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
        );
    };

    my-subtest 'is( undef, undef ) without name', {
        my-is( is( (Str), (Str) ), True, 'is returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            }
        );
    };

    my-subtest 'is( undef !=== undef ) without name', {
        my-is( is( (Str), (Int) ), False, 'is returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => (Str),
                            expected => (Int),
                            operator => (Any),
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'is( undef !=== defined ) without name', {
        my-is( is( (Str), 42 ), False, 'is returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => (Str),
                            expected => 42,
                            operator => (Any),
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'is( defined !=== undef ) without name', {
        my-is( is( 42, (Str) ), False, 'is returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => 42,
                            expected => (Str),
                            operator => (Any),
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'is( defined(Int) != defined(Int) ) without name', {
        my-is( is( 1, 2 ), False, 'is returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => 1,
                            expected => 2,
                            operator => (Any),
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'is( defined(Str) != defined(Int) ) without name', {
        my-is( is( 'foo', 2 ), False, 'is returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => 'foo',
                            expected => 2,
                            operator => (Any),
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'is( defined(Int) == defined(Int) ) without name', {
        my-is( is( 2, 2 ), True, 'is returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            }
        );
    };

    my-subtest 'is( defined(Str) == defined(Str) ) without name', {
        my-is( is( 'foo', 'foo' ), True, 'is returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            }
        );
    };

    my-subtest 'is( defined(Str) == defined(Str) ) with name', {
        my-is( is( 'foo', 'foo', 'two foos' ), True, 'is returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'two foos',
                    diagnostic => (Test::Stream::Diagnostic)
                },
            }
        );
    };

    my-subtest 'isnt( undef, undef ) without name', {
        my-is( isnt( (Str), (Str) ), False, 'isnt returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => (Str),
                            expected => (Str),
                            operator => &Test::Predicator::infix:<!===>,
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'isnt( undef !=== undef ) without name', {
        my-is( isnt( (Str), (Int) ), True, 'isnt returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic),
                },
            }
        );
    };

    my-subtest 'isnt( undef !=== defined ) without name', {
        my-is( isnt( (Str), 42 ), True, 'isnt returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic),
                },
            }
        );
    };

    my-subtest 'isnt( defined !=== undef ) without name', {
        my-is( isnt( 42, (Str) ), True, 'isnt returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic),
                },
            }
        );
    };

    my-subtest 'isnt( defined(Int) != defined(Int) ) without name', {
        my-is( isnt( 1, 2 ), True, 'isnt returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic),
                },
            }
        );
    };

    my-subtest 'isnt( defined(Str) != defined(Int) ) without name', {
        my-is( isnt( 'foo', 2 ), True, 'isnt returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic),
                },
            }
        );
    };

    my-subtest 'isnt( defined(Int) == defined(Int) ) without name', {
        my-is( isnt( 2, 2 ), False, 'isnt returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => False,
                    name   => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => 2,
                            expected => 2,
                            operator => &infix:<ne>,
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'isnt( defined(Str) == defined(Str) ) without name', {
        my-is( isnt( 'foo', 'foo' ), False, 'isnt returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => False,
                    name   => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => 'foo',
                            expected => 'foo',
                            operator => &infix:<ne>,
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'isnt( defined(Str) == defined(Str) ) with name', {
        my-is( isnt( 'foo', 'foo', 'two foos' ), False, 'isnt returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => False,
                    name   => 'two foos',
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => 'foo',
                            expected => 'foo',
                            operator => &infix:<ne>,
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'cmp-ok( 2 < 3 )', {
        my-is( cmp-ok( 2, «<», 3 ), True, 'cmp-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic),
                },
            }
        );
    };

    my-subtest 'cmp-ok( 2 > 3 )', {
        my-is( cmp-ok( 2, «>», 3 ), False, 'cmp-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => 2,
                            expected => 3,
                            operator => &infix:«>»,
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'cmp-ok( 2 not-an-op 3 )', {
        my-is( cmp-ok( 2, 'not-an-op', 3 ), False, 'cmp-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        message  => q{Could not use 'not-an-op' as a comparator},
                        more     => %(),
                    ),
                },
            }
        );
    };

    my-subtest 'isa-ok( $obj, $type )', {
        my-is( isa-ok( 42, Int ), True, 'isa-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'An object of class Int isa Int',
                },
            }
        );
    };

    my-subtest 'isa-ok( $obj, !$type )', {
        my-is( isa-ok( 42, Str ), False, 'isa-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => 'An object of class Int isa Str',
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        message  => 'Expected an object or class which is a Str or a subclass',
                    ),
                },
            },
        );
    };

    my-subtest 'isa-ok( $obj, $type, $name )', {
        my-is( isa-ok( 42, Int, 'my integer' ), True, 'isa-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'my integer',
                },
            }
        );
    };

    my-subtest 'isa-ok( $obj, !$type, $name )', {
        my-is( isa-ok( 42, Str, 'my string' ), False, 'isa-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => 'my string',
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        message  => 'Expected an object or class which is a Str or a subclass',
                    ),
                },
            },
        );
    };

    my-subtest 'does-ok( $obj, $role )', {
        my-is( does-ok( sub { }, Callable ), True, 'does-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'An object of class Sub does the role Callable',
                },
            }
        );
    };

    my-subtest 'does-ok( $obj, !$role )', {
        my-is( does-ok( 'string', Callable ), False, 'does-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => 'An object of class Str does the role Callable',
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        message  => 'An object of class Str does not do the role Callable',
                    ),
                },
            }
        );
    };

    my-subtest 'does-ok( $obj, $role, $name )', {
        my-is( does-ok( sub { }, Callable, 'sub does Callable' ), True, 'does-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'sub does Callable',
                },
            }
        );
    };

    my-subtest 'does-ok( $obj, !$role, $name )', {
        my-is( does-ok( 'string', Callable, 'string does Callable' ), False, 'does-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => False,
                    name   => 'string does Callable',
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        message  => 'An object of class Str does not do the role Callable',
                    ),
                },
            }
        );
    };

    my-subtest 'does-ok( $obj, $role, $name )', {
        my-is( does-ok( sub { }, Callable, 'sub does Callable' ), True, 'does-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'sub does Callable',
                },
            }
        );
    };

    my-subtest 'does-ok( $class, $role )', {
        my-is( does-ok( Method, Callable ), True, 'does-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'The class Method does the role Callable',
                },
            }
        );
    };

    my-subtest 'does-ok( $role, $role )', {
        my-is( does-ok( Mixy, Baggy ), True, 'does-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'The role Mixy does the role Baggy',
                },
            }
        );
    };

    my-subtest 'can-ok( $obj, $method )', {
        my-is( can-ok( 42, 'chr' ), True, 'can-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'An object of class Int has a method chr',
                },
            }
        );
    };

    my-subtest 'can-ok( $obj, !$method )', {
        my-is( can-ok( 42, 'foobar' ), False, 'can-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => False,
                    name   => 'An object of class Int has a method foobar',
                },
            }
        );
    };

    my-subtest 'can-ok( $obj, $method, $name )', {
        my-is( can-ok( 42, 'chr', 'Int can chr' ), True, 'can-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'Int can chr',
                },
            }
        );
    };

    my-subtest 'can-ok( $obj, !$method, $name )', {
        my-is( can-ok( 42, 'foobar', 'Int can foobar' ), False, 'can-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => False,
                    name   => 'Int can foobar',
                },
            }
        );
    };

    my-subtest 'can-ok( $class, $method )', {
        my-is( can-ok( Str, 'tc' ), True, 'can-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed => True,
                    name   => 'The class Str has a method tc',
                },
            }
        );
    };

    my-skip 'cannot call Baggy.^can()', 1;
    # my-subtest 'can-ok( $role, $method )', {
    #     my-is( can-ok( Baggy, 'grab' ), True, 'can-ok returns Bool' );
    #     test-event-stream(
    #         $listener,
    #         ${
    #             class  => Test::Stream::Event::Test,
    #             attributes => ${
    #                 passed => True,
    #                 name   => 'The role Baggy has a method grab',
    #             },
    #         }
    #     );
    # };

    my-subtest 'like( $str, $regex ) without name', {
        my-is( like( 'foo bar baz', rx{ 'bar' } ), True, 'like returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
        );
    };

    my-subtest 'like( $str, !$regex ) without name', {
        my-is( like( 'foo bar baz', rx{ 'blorg' } ), False, 'like returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more => ${
                            got      => 'foo bar baz',
                            expected => rx{ 'blorg' },
                            operator => &infix:<~~>,
                        },
                    ),
                },
            },
        );
    };

    my-subtest 'unlike( $str, $regex ) without name', {
        my-is( unlike( 'foo bar baz', rx{ 'blorg' } ), True, 'unlike returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
        );
    };

    my-subtest 'unlike( $str, !$regex ) without name', {
        my-is( unlike( 'foo bar baz', rx{ 'bar' } ), False, 'unlike returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more => ${
                            got      => 'foo bar baz',
                            expected => rx{ 'bar' },
                            operator => &infix:<!~~>,
                        },
                    ),
                },
            },
        );
    };

    my-subtest 'is-deeply( $str, $regex ) without name', {
        my-is(
            is-deeply(
                $[ 'array', 'with', ${ hash => 'ref' } ],
                $[ 'array', 'with', ${ hash => 'ref' } ],
            ),
            True,
            'is-deeply returns Bool'
        );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
        );
    };

    my-subtest 'is-deeply( $str, $regex ) without name', {
        my $got    = $[ 'array', 'with', ${ hash => 'ref' } ];
        my $expect = $[ 'array', 'with', $[ array => 'ref' ] ],;
        my-is( is-deeply( $got, $expect ), False, 'is-deeply returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more     => ${
                            got      => $got.perl,
                            expected => $expect.perl,
                            operator => &infix:<eqv>,
                        },
                    ),
                },
            },
        );
    };

    my-subtest 'lives-ok( lives )', {
        my $sub = sub { return 42 };
        my-is( lives-ok($sub), True, 'lives-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            }
        );
    };

    my-subtest 'lives-ok( dies )', {
        my $sub = sub { die 'I died' };
        my-is( lives-ok($sub), False, 'lives-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        more => {
                            exception => X::AdHoc.new( payload => 'I died' ),
                        },
                    ),
                },
            }
        );
    };

    my-subtest 'dies-ok( dies )', {
        my $sub = sub { die 42 };
        my-is( dies-ok($sub), True, 'dies-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            }
        );
    };

    my-subtest 'dies-ok( dies )', {
        my $sub = sub { return 42 };
        my-is( dies-ok($sub), False, 'dies-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        message  => 'The code ran without throwing an exception',
                    ),
                },
            }
        );
    };

    my-subtest 'dies-ok( dies )', {
        my $sub = sub { return 42 };
        my-is( dies-ok($sub), False, 'dies-ok returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => Test::Stream::Diagnostic.new(
                        severity => DiagnosticSeverity::failure,
                        message  => 'The code ran without throwing an exception',
                    ),
                },
            }
        );
    };

    my-subtest 'throws-like( $sub, X::AdHoc )', {
        my $sub = sub { die 'whatever' };
        my-is( throws-like( $sub, X::AdHoc ), True, 'throws-like returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'throws-like X::AdHoc',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => 'code throws an exception',
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => 'exception thrown by code isa X::AdHoc',
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'throws-like X::AdHoc',
                },
            },
        );
    };

    my-subtest 'throws-like( $sub, X::AdHoc, $name )', {
        my $sub = sub { die 'whatever' };
        my-is( throws-like( $sub, X::AdHoc, 'sub throws ad-hoc' ), True, 'throws-like returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'sub throws ad-hoc',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => 'code throws an exception',
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => 'exception thrown by code isa X::AdHoc',
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'sub throws ad-hoc',
                },
            },
        );
    };

    my-subtest 'throws-like( $sub does not die, X::AdHoc )', {
        my $sub = sub { return 42 };
        my-is( throws-like( $sub, X::AdHoc ), False, 'throws-like returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'throws-like X::AdHoc',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => 'code throws an exception',
                    diagnostic => (Test::Stream::Diagnostic),
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'throws-like X::AdHoc',
                },
            },
        );
    };

    my-subtest 'throws-like( $sub, $regex )', {
        my $sub = sub { die 'some message or other' };
        my-is( throws-like( $sub, rx{ 'some message' } ), True, 'throws-like returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'throws-like message content',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => 'code throws an exception',
                    diagnostic => (Test::Stream::Diagnostic),
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'throws-like message content',
                },
            },
        );
    };

    my-subtest 'throws-like( $sub, $regex, $name )', {
        my $sub = sub { die 'some message or other' };
        my-is( throws-like( $sub, rx{ 'some message' }, 'exception has our message' ), True, 'throws-like returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'exception has our message',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => 'code throws an exception',
                    diagnostic => (Test::Stream::Diagnostic),
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'exception has our message',
                },
            },
        );
    };

    my-subtest 'throws-like( $sub, $regex )', {
        my $sub = sub { die 'some message or other' };
        my-is( throws-like( $sub, rx{ 'not present' } ), False, 'throws-like returns Bool' );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'throws-like message content',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => 'code throws an exception',
                    diagnostic => (Test::Stream::Diagnostic),
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'throws-like message content',
                },
            },
        );
    };

    my-subtest 'todo()', {
        todo(
            'unimplemented', {
                ok(False);
            }
        );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Todo::Start,
                attributes => ${
                    reason => 'unimplemented',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                },
            },
            ${
                class  => Test::Stream::Event::Todo::End,
                attributes => ${
                    reason => 'unimplemented',
                },
            },
        );
    };

# disabled tests for now because of "skip" sub interaction post 2022.07+
#    my-subtest 'skip()', {
#        skip();
#        test-event-stream(
#            $listener,
#            ${
#                class  => Test::Stream::Event::Skip,
#                attributes => ${
#                    reason => (Str),
#                    count  => 1,
#                },
#            }
#        );
#    };
#
#    my-subtest 'skip(reason)', {
#        skip('because');
#        test-event-stream(
#            $listener,
#            ${
#                class  => Test::Stream::Event::Skip,
#                attributes => ${
#                    reason => 'because',
#                    count  => 1,
#                },
#            }
#        );
#    };
#
#    my-subtest 'skip( 2, reason )', {
#        skip( 'none', 2 );
#        test-event-stream(
#            $listener,
#            ${
#                class  => Test::Stream::Event::Skip,
#                attributes => ${
#                    reason => 'none',
#                    count  => 2,
#                },
#            }
#        );
#    };

    my-subtest 'diag(...)', {
        diag('some text');
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Diag,
                attributes => ${
                    message => 'some text',
                },
            }
        );
    };

    my-subtest 'subtest( subname, &block ) with passing subtest', {
        my-is(
            subtest(
                'subname',
                sub {
                    ok(True),
                }
            ),
            True,
            'subtest returns Bool'
        );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'subname',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'subname',
                },
            },
        );
    };

    my-subtest 'subtest( subname, &block ) with failing subtest', {
        my-is(
            subtest(
                'subname',
                sub {
                    ok(False),
                }
            ),
            False,
            'subtest returns Bool'
        );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'subname',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'subname',
                },
            },
        );
    };

    my-subtest 'nested subtests', {
        my-is(
            subtest(
                'subname',
                sub {
                    subtest( 'nested', sub { ok(False) } );
                    ok(True),
                }
            ),
            False,
            'subtest returns Bool'
        );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'subname',
                },
            },
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'nested',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => False,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'nested',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'subname',
                },
            },
        );
    };

    my-subtest 'subtest that runs no tests returns false', {
        my-is(
            subtest( 'no tests', sub { } ), False,
            'subtest returns Bool'
        );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'no tests',
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'no tests',
                },
            },
        );
    };

    my-subtest 'subtest with wrong plan returns false', {
        my-is(
            subtest(
                'plan is wrong',
                sub {
                    plan(2);
                    ok(True);
                }
            ),
            False,
            'subtest returns Bool'
        );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'plan is wrong',
                },
            },
            ${
                class  => Test::Stream::Event::Plan,
                attributes => ${
                    planned => 2,
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'plan is wrong',
                },
            },
        );
    };

    my-subtest 'nested subtest with wrong plan returns false', {
        my-is(
            subtest(
                'plan is correct',
                sub {
                    plan(2);
                    subtest(
                        'plan is wrong',
                        sub {
                            plan(2);
                            ok(True);
                        }
                    );
                    ok(True);
                }
            ),
            False,
            'subtest returns Bool'
        );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'plan is correct',
                },
            },
            ${
                class  => Test::Stream::Event::Plan,
                attributes => ${
                    planned => 2,
                },
            },
            ${
                class  => Test::Stream::Event::Suite::Start,
                attributes => ${
                    name => 'plan is wrong',
                },
            },
            ${
                class  => Test::Stream::Event::Plan,
                attributes => ${
                    planned => 2,
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'plan is wrong',
                },
            },
            ${
                class  => Test::Stream::Event::Test,
                attributes => ${
                    passed     => True,
                    name       => (Str),
                    diagnostic => (Test::Stream::Diagnostic)
                },
            },
            ${
                class  => Test::Stream::Event::Suite::End,
                attributes => ${
                    name => 'plan is correct',
                },
            },
        );
    };
}

{
    my $listener = listener();

    my-subtest 'skip-all()', {
        skip-all();
        test-event-stream(
            $listener,
            ${
                class      => Test::Stream::Event::Suite::Start,
                attributes => ${ name => '300-predicates.t' },
            },
            ${
                class  => Test::Stream::Event::SkipAll,
                attributes => ${
                    reason => (Str),
                },
            }
        );
    };
}

{
    my $listener = listener();

    my-subtest 'skip-all()', {
        skip-all('why not');
        test-event-stream(
            $listener,
            ${
                class      => Test::Stream::Event::Suite::Start,
                attributes => ${ name => '300-predicates.t' },
            },
            ${
                class  => Test::Stream::Event::SkipAll,
                attributes => ${
                    reason => 'why not',
                },
            }
        );
    };
}

Test::Predicates::clear-instance-violently-for-test-stream-tests;

my-done-testing;

sub listener (--> Test::Stream::Recorder:D) {
    Test::Stream::Hub.clear-instance-violently-for-test-stream-tests;
    Test::Predicates::clear-instance-violently-for-test-stream-tests;
    my $hub = Test::Stream::Hub.instance;
    my $listener = Test::Stream::Recorder.new;
    $hub.add-listener($listener);

    return $listener;
}
