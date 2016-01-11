use v6;
use lib 'lib', 't/lib';

use My::Listener;
use My::TAP;
use Test::Predicates;
use Test::Stream::Diagnostic;
use Test::Stream::Types;

say "1..386";

{
    my $hub = Test::Stream::Hub.instance;
    my $listener = My::Listener.new;
    $hub.add-listener($listener);

    my-diag('plan(42)');
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

    my-diag('ok(True) without name');
    my-ok( ok(True) === True, 'ok returns bool' );
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

    my-diag('ok(False) without name');
    my-ok( ok(False) === False, 'ok returns bool' );
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

    my-diag('ok(True) with name');
    my-ok( ok( True, 'is true' ) === True, 'ok returns bool' );
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

    my-diag('ok(False) with name');
    my-ok( ok( False, 'is false' ) === False, 'ok returns bool' );
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

    my-diag('is( undef === undef ) without name');
    my-ok( is( (Str), (Str) ) === True, 'is returns bool' );
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

    my-diag('is( undef !=== undef ) without name');
    my-ok( is( (Str), (Int) ) === False, 'is returns bool' );
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

    my-diag('is( undef !=== defined ) without name');
    my-ok( is( (Str), 42 ) === False, 'is returns bool' );
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

    my-diag('is( defined !=== undef ) without name');
    my-ok( is( 42, (Str) ) === False, 'is returns bool' );
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

    my-diag('is( defined(Int) != defined(Int) ) without name');
    my-ok( is( 1, 2 ) === False, 'is returns bool' );
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

    my-diag('is( defined(Str) != defined(Int) ) without name');
    my-ok( is( 'foo', 2 ) === False, 'is returns bool' );
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

    my-diag('is( defined(Int) == defined(Int) ) without name');
    my-ok( is( 2, 2 ) === True, 'is returns bool' );
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

    my-diag('is( defined(Str) == defined(Str) ) without name');
    my-ok( is( 'foo', 'foo' ) === True, 'is returns bool' );
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

    my-diag('is( defined(Str) == defined(Str) ) with name');
    my-ok( is( 'foo', 'foo', 'two foos' ) === True, 'is returns bool' );
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

    my-diag('isnt( undef === undef ) without name');
    my-ok( isnt( (Str), (Str) ) === False, 'isnt returns bool' );
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
                        operator => do {
                            use MONKEY-SEE-NO-EVAL;
                            EVAL('&infix:<!===>');
                        },
                    },
                ),
            },
        }
    );

    my-diag('isnt( undef !=== undef ) without name');
    my-ok( isnt( (Str), (Int) ) === True, 'isnt returns bool' );
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

    my-diag('isnt( undef !=== defined ) without name');
    my-ok( isnt( (Str), 42 ) === True, 'isnt returns bool' );
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

    my-diag('isnt( defined !=== undef ) without name');
    my-ok( isnt( 42, (Str) ) === True, 'isnt returns bool' );
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

    my-diag('isnt( defined(Int) != defined(Int) ) without name');
    my-ok( isnt( 1, 2 ) === True, 'isnt returns bool' );
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

    my-diag('isnt( defined(Str) != defined(Int) ) without name');
    my-ok( isnt( 'foo', 2 ) === True, 'isnt returns bool' );
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

    my-diag('isnt( defined(Int) == defined(Int) ) without name');
    my-ok( isnt( 2, 2 ) === False, 'isnt returns bool' );
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

    my-diag('isnt( defined(Str) == defined(Str) ) without name');
    my-ok( isnt( 'foo', 'foo' ) === False, 'isnt returns bool' );
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

    my-diag('isnt( defined(Str) == defined(Str) ) with name');
    my-ok( isnt( 'foo', 'foo', 'two foos' ) === False, 'isnt returns bool' );
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

    my-diag('cmp-ok( 2 < 3 )');
    my-ok( cmp-ok( 2, «<», 3 ) === True, 'cmp-ok returns bool' );
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

    my-diag('cmp-ok( 2 > 3 )');
    my-ok( cmp-ok( 2, «>», 3 ) === False, 'cmp-ok returns bool' );
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

    my-diag('cmp-ok( 2 not-an-op 3 )');
    my-ok( cmp-ok( 2, 'not-an-op', 3 ) === False, 'cmp-ok returns bool' );
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

    my-diag('skip()');
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

    my-diag('skip(reason)');
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

    my-diag('skip( 2, reason )');
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

    my-diag('diag(...)');
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

    my-diag('subtest( subname, &block ) with passing subtest');
    my-ok(
        subtest(
            'subname',
            sub {
                ok(True),
            }
        ) == True,
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

    my-diag('subtest( subname, &block ) with failing subtest');
    my-ok(
        subtest(
            'subname',
            sub {
                ok(False),
            }
        ) == False,
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

    my-diag('nested subtests');
    my-ok(
        subtest(
            'subname',
            sub {
                subtest( 'nested', sub { ok(False) } );
                ok(True),
            }
        ) == False,
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

    my-diag('subtest that runs no tests returns false');
    my-ok(
        subtest( 'no tests', sub { } ) == False,
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

    my-diag('subtest with wrong plan returns false');
    my-ok(
        subtest(
            'plan is wrong',
            sub {
                plan(2);
                ok(True);
            }
        ) == False,
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

    my-diag('nested subtest with wrong plan returns false');
    my-ok(
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
        ) == False,
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
}

{
    Test::Stream::Hub.clear-instance-violently-for-test-stream-tests;
    Test::Predicates::clear-instance-violently-for-test-stream-tests;
    my $hub = Test::Stream::Hub.instance;
    my $listener = My::Listener.new;
    $hub.add-listener($listener);

    my-diag('skip-all()');
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
}

{
    Test::Stream::Hub.clear-instance-violently-for-test-stream-tests;
    Test::Predicates::clear-instance-violently-for-test-stream-tests;
    my $hub = Test::Stream::Hub.instance;
    my $listener = My::Listener.new;
    $hub.add-listener($listener);

    my-diag('skip-all()');
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
}
