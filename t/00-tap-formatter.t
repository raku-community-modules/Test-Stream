use v6;
use lib 'lib', 't/lib';;

use IO::String;
use Test::Stream::Event;
use Test::Stream::Formatter::TAP12;
use Test::Stream::Types;

# Note that this test cannot use Test.pm6 (because I hope that module will
# eventually be built on top of Test::Stream), nor any other test
# module. Instead, we'll print raw TAP. Once this test passes other tests can
# safely rely on Test::Stream::TAP12::Formatter.

# Every event we send generates 4 basic tests ...
#    - did it throw an exception?
#    - do each of the 3 output handles contain the expected output?
# Every formatter test adds three finalize tests
my $test-count = 136;
say "1..$test-count";

my-diag('No subtests, all tests passing');
test-formatter(
    event-tests => $[
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Plan,
            args  => ${
                planned => 2,
            },
            expect => ${
                output         => "1..2\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'test 1',
            },
            expect => ${
                output         => "ok 1 - test 1\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'something',
            },
            expect => ${
                output         => "ok 2 - something\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
    exit-code => 0,
    error     => q{},
);

my-diag('Failures, todo, and skip');
test-formatter(
    event-tests => $[
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Plan,
            args  => ${
                planned => 5,
            },
            expect => ${
                output         => "1..5\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'passed',
            },
            expect => ${
                output         => "ok 1 - passed\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'failed',
            },
            expect => ${
                output         => "not ok 2 - failed\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo,
            args  => ${
                count  => 1,
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'needs fixing',
            },
            expect => ${
                output         => "not ok 3 - needs fixing # TODO not yet done\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Skip,
            args  => ${
                count  => 2,
                reason => 'bad platform',
            },
            expect => ${
                output         => "ok 4 # skip bad platform\nok 5 # skip bad platform\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "# Looks like you failed 1 test out of 5.\n",
            },
        },
    ],
    exit-code => 1,
    error     => 'failed 1 test',
);

my-diag('Diagnostics attached to tests (including pass, failure, TODO tests, and arbtitrary %more for the diagnostic object)');
test-formatter(
    event-tests => $[
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Plan,
            args  => ${
                planned => 4,
            },
            expect => ${
                output         => "1..4\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'no diag should show',
                # This is a bit of a pathological case since in "normal" TAP12
                # nothing should ever include a diagnostic with a passing test,
                # but better to test that this does the right thing than find out
                # later that it's broken.
                diagnostic => Test::Stream::Diagnostic.new(
                    severity => DiagnosticSeverity::comment,
                    message  => 'should not be seen',
                    more     => ${ foo => 42 },
                ),
            },
            expect => ${
                output         => "ok 1 - no diag should show\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'should include diag info',
                diagnostic => Test::Stream::Diagnostic.new(
                    severity => DiagnosticSeverity::failure,
                    message  => 'did not get the answer',
                    more     => ${
                        got      => 41,
                        operator => '==',
                        expected => 42,
                    },
                ),
            },
            expect => ${
                output         => "not ok 2 - should include diag info\n",
                todo-output    => q{},
                failure-output => q:to/FAILURE/,
                # did not get the answer
                #     expected : 42
                #     operator : ==
                #          got : 41
                FAILURE
            },
        },
        ${
            event => Test::Stream::Event::Todo,
            args  => ${
                count  => 1,
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'needs fixing',
                diagnostic => Test::Stream::Diagnostic.new(
                    severity => DiagnosticSeverity::todo,
                    message  => 'expected large size',
                    more     => ${
                        got      => 'medium',
                        expected => 'large',
                    },
                ),
            },
            expect => ${
                output         => "not ok 3 - needs fixing # TODO not yet done\n",
                todo-output    => q:to/TODO/,
                # expected large size
                #     expected : "large"
                #          got : "medium"
                TODO
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'diag.more has arbitrary keys',
                diagnostic => Test::Stream::Diagnostic.new(
                    severity => DiagnosticSeverity::failure,
                    message  => 'did not get the answer',
                    more     => ${
                        with => 'arbitrary',
                        keys => $[ 1, 2, 3 ],
                    },
                ),
            },
            expect => ${
                output         => "not ok 4 - diag.more has arbitrary keys\n",
                todo-output    => q{},
                failure-output => q:to/FAILURE/,
                # did not get the answer
                #     keys : $[1, 2, 3]
                #     with : "arbitrary"
                FAILURE
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "# Looks like you failed 2 tests out of 4.\n",
            },
        },
    ],
    exit-code => 2,
    error     => 'failed 2 tests',
);

my-diag('Subtests with diagnostics, skip, todo, etc.');
test-formatter(
    event-tests => $[
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Plan,
            args  => ${
                planned => 4,
            },
            expect => ${
                output         => "1..4\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'pre-subtest',
            },
            expect => ${
                output         => "ok 1 - pre-subtest\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => 'this is sub 1',
            },
            expect => ${
                output         => "# Subtest this is sub 1\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'should include diag info',
                diagnostic => Test::Stream::Diagnostic.new(
                    severity => DiagnosticSeverity::failure,
                    message  => 'did not get the answer',
                    more     => ${
                        got      => 41,
                        operator => '==',
                        expected => 42,
                    },
                ),
            },
            expect => ${
                output         => "    not ok 1 - should include diag info\n",
                todo-output    => q{},
                failure-output => q:to/FAILURE/,
                    # did not get the answer
                    #     expected : 42
                    #     operator : ==
                    #          got : 41
                FAILURE
            },
        },
        ${
            event => Test::Stream::Event::Todo,
            args  => ${
                count  => 1,
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'needs fixing',
                diagnostic => Test::Stream::Diagnostic.new(
                    severity => DiagnosticSeverity::todo,
                    message  => 'expected large size',
                    more     => ${
                        got      => 'medium',
                        expected => 'large',
                    },
                ),
            },
            expect => ${
                output         => "    not ok 2 - needs fixing # TODO not yet done\n",
                todo-output    => q:to/TODO/,
                    # expected large size
                    #     expected : "large"
                    #          got : "medium"
                TODO
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'diag.more has arbitrary keys',
                diagnostic => Test::Stream::Diagnostic.new(
                    severity => DiagnosticSeverity::failure,
                    message  => 'did not get the answer',
                    more     => ${
                        with => 'arbitrary',
                        keys => $[ 1, 2, 3 ],
                    },
                ),
            },
            expect => ${
                output         => "    not ok 3 - diag.more has arbitrary keys\n",
                todo-output    => q{},
                failure-output => q:to/FAILURE/,
                    # did not get the answer
                    #     keys : $[1, 2, 3]
                    #     with : "arbitrary"
                FAILURE
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => 'this is sub 1',
            },
            expect => ${
                output         => "    1..3\n" ~ "not ok 2 - this is sub 1\n",
                todo-output    => q{},
                failure-output => "    # Looks like you failed 2 tests out of 3.\n",
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "# Looks like you failed 1 test out of 2.\n",
            },
        },
    ],
    exit-code => 1,
    error     => 'failed 1 test',
);

my-diag('Diag from passing, failing, and todo test, in top-level test and subtests');
test-formatter(
    event-tests => $[
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'passed',
            },
            expect => ${
                output         => "ok 1 - passed\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Diag,
            args  => ${
                message => 'diag 1',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "# diag 1\n",
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'failed',
            },
            expect => ${
                output         => "not ok 2 - failed\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Diag,
            args  => ${
                message => 'diag 2',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "# diag 2\n",
            },
        },
        ${
            event => Test::Stream::Event::Todo,
            args  => ${
                count  => 1,
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'needs fixing',
            },
            expect => ${
                output         => "not ok 3 - needs fixing # TODO not yet done\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Diag,
            args  => ${
                message => 'diag 3',
            },
            expect => ${
                output         => q{},
                todo-output    => "# diag 3\n",
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => 'subtest',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'passed',
            },
            expect => ${
                output         => "    ok 1 - passed\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Diag,
            args  => ${
                message => 'diag 1',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "    # diag 1\n",
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'failed',
            },
            expect => ${
                output         => "    not ok 2 - failed\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Diag,
            args  => ${
                message => 'diag 2',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "    # diag 2\n",
            },
        },
        ${
            event => Test::Stream::Event::Todo,
            args  => ${
                count  => 1,
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'needs fixing',
            },
            expect => ${
                output         => "    not ok 3 - needs fixing # TODO not yet done\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Diag,
            args  => ${
                message => 'diag 3',
            },
            expect => ${
                output         => q{},
                todo-output    => "    # diag 3\n",
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => 'subtest',
            },
            expect => ${
                output         => qq{    1..3\nnot ok 4 - subtest\n},
                todo-output    => q{},
                failure-output => "    # Looks like you failed 1 test out of 3.\n",
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => "1..4\n",
                todo-output    => q{},
                failure-output => "# Looks like you failed 2 tests out of 4.\n",
            },
        },
    ],
    exit-code => 2,
    error     => 'failed 2 tests',
);

my-diag('Bail out');
test-formatter(
    event-tests => $[
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Bail,
            args  => ${
                reason => 'explosive decompression',
            },
            expect => ${
                output         => "Bail out!  explosive decompression\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
    exit-code => 255,
    error     => 'Bailed out - explosive decompression',
);

my-diag('Bail out in a subtest');
test-formatter(
    event-tests => $[
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => 'testing a thing',
            },
            expect => ${
                output         => "# Subtest testing a thing\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Bail,
            args  => ${
                reason => 'cannot handle subtests',
            },
            expect => ${
                output         => "Bail out!  cannot handle subtests\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
    exit-code => 255,
    error     => 'Bailed out - cannot handle subtests',
);

my-diag('Skip all');
test-formatter(
    event-tests => $[
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::SkipAll,
            args  => ${
                reason => 'feeling tired',
            },
            expect => ${
                output         => "1..0 # Skipped: feeling tired\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
    exit-code => 0,
    error     => q{},
);

my-diag('Skip all in a subtest');
test-formatter(
    event-tests => $[
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'pre-subtest',
            },
            expect => ${
                output         => "ok 1 - pre-subtest\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::Start,
            args  => ${
                name => 'will skip',
            },
            expect => ${
                output         => "# Subtest will skip\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::SkipAll,
            args  => ${
                reason => 'feeling tired',
            },
            expect => ${
                output         => qq{    1..0 # Skipped: feeling tired\n},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => 'will skip',
            },
            expect => ${
                output         => "ok 2 - will skip\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'post-subtest',
            },
            expect => ${
                output         => "ok 3 - post-subtest\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Suite::End,
            args  => ${
                name => '00-tap-formatter.t',
            },
            expect => ${
                output         => "1..3\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
    exit-code => 0,
    error     => q{},
);

sub test-formatter (:@event-tests, :$exit-code, :$error) {
    my %outputs = (
        output         => IO::String.new,
        todo-output    => IO::String.new,
        failure-output => IO::String.new,
    );

    my $tap = Test::Stream::Formatter::TAP12.new(|%outputs);

    for @event-tests -> $test {
        test-event-output(
            $tap,
            $test<event>.new( |$test<args> ),
            %outputs,
            $test<expect>,
        );
        $_.clear for %outputs.values;
    }

    my $status = my-lives-ok(
        'calling finalize',
        { $tap.finalize },
    );
    
    my-ok(
        $status.exit-code == $exit-code,
        "finalize returned $exit-code for exit code",
        "got {$status.exit-code} instead",
    );
    my-ok(
        $status.error eq $error,
        'finalize returned expected error message (if any)',
        $status.error,
    );
}

sub test-event-output (
    Test::Stream::Formatter::TAP12:D $tap,
    Test::Stream::Event:D $event,
    %outputs,
    %expect,
) {
    my-lives-ok(
        "sending {$event.type} to formatter",
        { $tap.accept-event($event) },
    );

    for < output todo-output failure-output > -> $h {
        compare-outputs( $event.type, $h, %outputs, %expect );
    }
}

sub compare-outputs (Str:D $type, Str:D $key, %outputs, %expect) {
    my $ok = %outputs{$key} ~~ %expect{$key};

    my @diag;
    unless $ok {
        @diag.append:
            q{expected : }
            ~ ( %expect{$key} ~~ Str
                    ?? %expect{$key}.Str.subst( :g, "\n", '\\n' )
                    !! %expect{$key}.perl );
        @diag.append:
            q{     got : } ~ %outputs{$key}.Str.subst( :g, "\n", '\\n' );
    }
        
    my-ok(
        ?$ok,
        "got expected $key for $type",
        @diag,
    );
}

sub my-lives-ok (Str:D $name, Code $code) {
    my $return = $code();
 
    my-ok( True, "no exception from $name" );
    CATCH {
        default {
            my-ok(
                False,
                "no exception from $name",
                $_.Str.lines.flat,
                $_.backtrace.Str.lines.flat,
            );
        }
    }

    return $return;
}

sub my-ok (Bool:D $ok, Str:D $name, *@diag) {
    state $test-num = 1;

    my $start = $ok ?? q{} !! q{not };
    say $start, q{ok - }, $test-num++, " $name";
    unless $ok {
        my-diag($_) for @diag.values 
    }
    return $ok;
}


sub my-diag (Str:D $message) {
    $*ERR.say( q{# }, escape($message) );
}

sub escape (Str:D $text) {
    return $text.subst( :g, q{#}, Q{\#} ).subst( :g, "\n", "\n#" );
}
