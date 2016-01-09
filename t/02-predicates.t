use v6;
use lib 'lib', 't/lib';

use My::Listener;
use My::TAP;
use Test::Predicates;
use Test::Stream::Diagnostic;
use Test::Stream::Types;

my $hub = Test::Stream::Hub.instance;
my $listener = My::Listener.new;

$hub.add-listener($listener);

my-diag('ok(True) without name');
my-ok( ok(True) === True, 'ok returns bool' );
test-event-stream(
    ${
        class      => 'Test::Stream::Event::Suite::Start',
        attributes => ${ name => '02-predicates.t' },
    },
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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
    ${
        class  => 'Test::Stream::Event::Test',
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

sub test-event-stream (*@expect) {
    my @got = $listener.events;
    my-ok(
        @got.elems == @expect.elems,
        'got the expected number of events'
    ) or my-diag("got {@got.elems}, expected {@expect.elems}");

    for @got Z @expect -> ($g, $e) {
        my $class = $e<class>;
        my-ok(
            $g.isa($class),
            "got a $class event"
        ) or my-diag("got a {$g.^name} instead");

        for $e<attributes>.keys -> $k {
            my-ok(
                ?$g.can($k),
                "event has a $k method"
            ) or next;

            my ($ok, $diag) = is-eq( $g."$k"(), $e<attributes>{$k} );
            my-ok(
                $ok,
                "event has the expected $k attribute"
            ) or my-diag($diag);
        }
    }

    $listener.clear;
}

sub is-eq ($g, $e) {
    my ($ok, $diag) = do given $e {
        when !*.defined {
            $g === $e;
        }
        when Callable {
            $g.defined && $g ~~ Callable && $g.name === $e.name;
        }
        when Bool {
            $g ~~ Bool && $e ?? $g !! !$g;
        }
        when Str {
            $g.defined && $g eq $e;
        }
        when Int {
            $g.defined && $g == $e;
        }
        when Test::Stream::Diagnostic {
            my $o = False;
            my $d;
            if $g.defined
               && $g ~~ Test::Stream::Diagnostic
               && $g.severity == $e.severity
               && $g.message === $e.message {

                $o = True;
                for $e.more.keys -> $k {
                    ($o, $d) = is-eq( $g.more{$k}, $e.more{$k} );
                    next if $o;
                    $d = "diagnostic.more<$k> - $d";
                    last;
                }
            }
            ($o, $d);
        }            
    };

    $diag //= qq[got: {stringify($g)}, expected: {stringify($e)}];

    return ($ok, $diag);
}

sub stringify ($thing) {
    return $thing.^name unless $thing.defined;
    return $thing.name if $thing ~~ Callable && $thing.name.defined;
    return $thing.gist if $thing ~~ Sub;
    return $thing;
}
