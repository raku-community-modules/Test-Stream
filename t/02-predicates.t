use v6;
use lib 'lib', 't/lib';

use My::Listener;
use My::Test;
use Test::Predicates;
use Test::Stream::Diagnostic;
use Test::Stream::Types;

{
    my $listener = listener();

    my-subtest 'plan(42)', {
        plan(42);
        test-event-stream(
            $listener,
            ${
                class      => Test::Stream::Event::Suite::Start,
                attributes => ${ name => '02-predicates.t' },
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
        my-is( ok(True), True, 'ok returns bool' );
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
        my-is( ok(False), False, 'ok returns bool' );
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
        my-is( ok( True, 'is true' ), True, 'ok returns bool' );
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
        my-is( ok( False, 'is false' ), False, 'ok returns bool' );
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

    my-subtest 'pass()', {
        my-is( pass(), True, 'pass returns bool' );
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
        my-is( flunk(), False, 'flunk returns bool' );
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
        my-is( is( (Str), (Str) ), True, 'is returns bool' );
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
        my-is( is( (Str), (Int) ), False, 'is returns bool' );
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
        my-is( is( (Str), 42 ), False, 'is returns bool' );
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
        my-is( is( 42, (Str) ), False, 'is returns bool' );
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
        my-is( is( 1, 2 ), False, 'is returns bool' );
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
        my-is( is( 'foo', 2 ), False, 'is returns bool' );
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
        my-is( is( 2, 2 ), True, 'is returns bool' );
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
        my-is( is( 'foo', 'foo' ), True, 'is returns bool' );
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
        my-is( is( 'foo', 'foo', 'two foos' ), True, 'is returns bool' );
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
        my-is( isnt( (Str), (Str) ), False, 'isnt returns bool' );
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
        my-is( isnt( (Str), (Int) ), True, 'isnt returns bool' );
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
        my-is( isnt( (Str), 42 ), True, 'isnt returns bool' );
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
        my-is( isnt( 42, (Str) ), True, 'isnt returns bool' );
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
        my-is( isnt( 1, 2 ), True, 'isnt returns bool' );
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
        my-is( isnt( 'foo', 2 ), True, 'isnt returns bool' );
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
        my-is( isnt( 2, 2 ), False, 'isnt returns bool' );
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
        my-is( isnt( 'foo', 'foo' ), False, 'isnt returns bool' );
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
        my-is( isnt( 'foo', 'foo', 'two foos' ), False, 'isnt returns bool' );
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
        my-is( cmp-ok( 2, «<», 3 ), True, 'cmp-ok returns bool' );
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
        my-is( cmp-ok( 2, «>», 3 ), False, 'cmp-ok returns bool' );
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
        my-is( cmp-ok( 2, 'not-an-op', 3 ), False, 'cmp-ok returns bool' );
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
        my-is( isa-ok( 42, Int ), True, 'isa-ok returns bool' );
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
        my-is( isa-ok( 42, Str ), False, 'isa-ok returns bool' );
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
        my-is( isa-ok( 42, Int, 'my integer' ), True, 'isa-ok returns bool' );
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
        my-is( isa-ok( 42, Str, 'my string' ), False, 'isa-ok returns bool' );
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
        my-is( does-ok( sub { }, Callable ), True, 'does-ok returns bool' );
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
        my-is( does-ok( 'string', Callable ), False, 'does-ok returns bool' );
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
        my-is( does-ok( sub { }, Callable, 'sub does Callable' ), True, 'does-ok returns bool' );
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
        my-is( does-ok( 'string', Callable, 'string does Callable' ), False, 'does-ok returns bool' );
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
        my-is( does-ok( sub { }, Callable, 'sub does Callable' ), True, 'does-ok returns bool' );
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
        my-is( does-ok( Method, Callable ), True, 'does-ok returns bool' );
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
        my-is( does-ok( Mixy, Baggy ), True, 'does-ok returns bool' );
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
        my-is( can-ok( 42, 'chr' ), True, 'can-ok returns bool' );
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
        my-is( can-ok( 42, 'foobar' ), False, 'can-ok returns bool' );
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
        my-is( can-ok( 42, 'chr', 'Int can chr' ), True, 'can-ok returns bool' );
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
        my-is( can-ok( 42, 'foobar', 'Int can foobar' ), False, 'can-ok returns bool' );
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
        my-is( can-ok( Str, 'tc' ), True, 'can-ok returns bool' );
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
    #     my-is( can-ok( Baggy, 'grab' ), True, 'can-ok returns bool' );
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

    my-subtest 'skip()', {
        skip();
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Skip,
                attributes => ${
                    reason => (Str),
                    count  => 1,
                },
            }
        );
    };

    my-subtest 'skip(reason)', {
        skip('because');
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Skip,
                attributes => ${
                    reason => 'because',
                    count  => 1,
                },
            }
        );
    };

    my-subtest 'skip( 2, reason )', {
        skip( 'none', 2 );
        test-event-stream(
            $listener,
            ${
                class  => Test::Stream::Event::Skip,
                attributes => ${
                    reason => 'none',
                    count  => 2,
                },
            }
        );
    };

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
            'subtest returns bool'
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
            'subtest returns bool'
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
            'subtest returns bool'
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
            'subtest returns bool'
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
            'subtest returns bool'
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
            'subtest returns bool'
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
    Test::Stream::Hub.clear-instance-violently-for-test-stream-tests;
    Test::Predicates::clear-instance-violently-for-test-stream-tests;
    my $hub = Test::Stream::Hub.instance;
    my $listener = My::Listener.new;
    $hub.add-listener($listener);

    my-subtest 'skip-all()', {
        skip-all();
        test-event-stream(
            $listener,
            ${
                class      => Test::Stream::Event::Suite::Start,
                attributes => ${ name => '02-predicates.t' },
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
    Test::Stream::Hub.clear-instance-violently-for-test-stream-tests;
    Test::Predicates::clear-instance-violently-for-test-stream-tests;
    my $hub = Test::Stream::Hub.instance;
    my $listener = My::Listener.new;
    $hub.add-listener($listener);

    my-subtest 'skip-all()', {
        skip-all('why not');
        test-event-stream(
            $listener,
            ${
                class      => Test::Stream::Event::Suite::Start,
                attributes => ${ name => '02-predicates.t' },
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

my-done-testing;

sub listener (--> My::Listener:D) {
    Test::Stream::Hub.clear-instance-violently-for-test-stream-tests;
    Test::Predicates::clear-instance-violently-for-test-stream-tests;
    my $hub = Test::Stream::Hub.instance;
    my $listener = My::Listener.new;
    $hub.add-listener($listener);

    return $listener;
}
