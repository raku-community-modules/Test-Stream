# Warning - the emacs uncomment-region command will seriously screw up many
# parts of this test!

use v6;
use lib 'lib', 't/lib';

use My::IO::String;
use My::Test;
use Test::Stream::Event;
use Test::Stream::Formatter::TAP12;
use Test::Stream::Hub;
use Test::Stream::Types;

my-diag('No subtests, all tests passing');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
);

my-diag('Failures, todo, and skip');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
                name   => 'will fail',
            },
            expect => ${
                output         => "not ok 2 - will fail\n",
                todo-output    => q{},
                failure-output => qq:to/FAILURE/,
                #   Failed test 'will fail'
                #   at $*PROGRAM-NAME line 1381
                FAILURE
            },
        },
        ${
            event => Test::Stream::Event::Todo::Start,
            args  => ${
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
                todo-output    => qq:to/TODO/,
                #   Failed (TODO) test 'needs fixing'
                #   at $*PROGRAM-NAME line 1381
                TODO
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo::End,
            args  => ${
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
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
                output         => q:to/OUTPUT/,
                ok 4 # skip bad platform
                ok 5 # skip bad platform
                OUTPUT
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "# Looks like you failed 1 test out of 5.\n",
            },
        },
    ],
);

my-diag(Q{Escaping of # and \ in test names, diag messages, todo & skip reasons});
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
                planned => 3,
            },
            expect => ${
                output         => "1..3\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => True,
                name   => 'has hash mark (#) and backslash (\\)',
            },
            expect => ${
                output         => Q{ok 1 - has hash mark (\#) and backslash (\\)} ~ "\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Diag,
            args  => ${
                message => 'has hash mark (#) and backslash (\\)',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => Q{# has hash mark (\#) and backslash (\\)} ~ "\n",
            },
        },
        ${
            event => Test::Stream::Event::Todo::Start,
            args  => ${
                reason => 'has hash mark (#) and backslash (\\)',
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
            },
            expect => ${
                output         => Q{ok 2 # TODO has hash mark (\#) and backslash (\\)} ~ "\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo::End,
            args  => ${
                reason => 'has hash mark (#) and backslash (\\)',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Skip,
            args  => ${
                count  => 1,
                reason => 'has hash mark (#) and backslash (\\)',
            },
            expect => ${
                output         => Q{ok 3 # skip has hash mark (\#) and backslash (\\)} ~ "\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
);

my-diag(Q{Escaping # of and \ in SkipAll reason});
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
                reason => 'has hash mark (#) and backslash (\\)',
            },
            expect => ${
                output         => Q{1..0 # Skipped: has hash mark (\#) and backslash (\\)} ~ "\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
);

my-diag('Plan does not match count of tests run');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
                name   => 'passed',
            },
            expect => ${
                output         => "ok 1 - passed\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "# You planned 2 tests but ran 1 test.\n",
            },
        },
    ],
);

my-diag('Diagnostics attached to tests (including pass, failure, TODO tests, and arbtitrary %more for the diagnostic object)');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
                        operator => &infix:<==>,
                        expected => 42,
                    },
                ),
            },
            expect => ${
                output         => "not ok 2 - should include diag info\n",
                todo-output    => q{},
                failure-output => qq:to/FAILURE/,
                #   Failed test 'should include diag info'
                #   at $*PROGRAM-NAME line 1381
                # did not get the answer
                #     expected : 42
                #     operator : infix:<==>
                #          got : 41
                FAILURE
            },
        },
        ${
            event => Test::Stream::Event::Todo::Start,
            args  => ${
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
                output         => qq{not ok 3 - needs fixing # TODO not yet done\n},
                todo-output    => qq:to/TODO/,
                #   Failed (TODO) test 'needs fixing'
                #   at $*PROGRAM-NAME line 1381
                # expected large size
                #     expected : "large"
                #          got : "medium"
                TODO
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo::End,
            args  => ${
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
                failure-output => qq:to/FAILURE/,
                #   Failed test 'diag.more has arbitrary keys'
                #   at $*PROGRAM-NAME line 1381
                # did not get the answer
                #     keys : \$[1, 2, 3]
                #     with : "arbitrary"
                FAILURE
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "# Looks like you failed 2 tests out of 4.\n",
            },
        },
    ],
);

my-diag('Subtests with diagnostics, skip, todo, etc.');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
                name   => 'pre-subtest',
            },
            expect => ${
                output         => "ok 1 - pre-subtest\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-start',
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
                        operator => &infix:<==>,
                        expected => 42,
                    },
                ),
            },
            expect => ${
                output         => qq{    not ok 1 - should include diag info\n},
                todo-output    => q{},
                failure-output => qq:to/FAILURE/,
                    #   Failed test 'should include diag info'
                    #   at $*PROGRAM-NAME line 1381
                    # did not get the answer
                    #     expected : 42
                    #     operator : infix:<==>
                    #          got : 41
                FAILURE
            },
        },
        ${
            event => Test::Stream::Event::Todo::Start,
            args  => ${
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
                output         => qq{    not ok 2 - needs fixing # TODO not yet done\n},
                todo-output    => qq:to/TODO/,
                    #   Failed (TODO) test 'needs fixing'
                    #   at $*PROGRAM-NAME line 1381
                    # expected large size
                    #     expected : "large"
                    #          got : "medium"
                TODO
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo::End,
            args  => ${
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
                output         => qq{    not ok 3 - diag.more has arbitrary keys\n},
                todo-output    => q{},
                failure-output => qq:to/FAILURE/,
                    #   Failed test 'diag.more has arbitrary keys'
                    #   at $*PROGRAM-NAME line 1381
                    # did not get the answer
                    #     keys : \$[1, 2, 3]
                    #     with : "arbitrary"
                FAILURE
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => 'this is sub 1',
            },
            expect => ${
                output         => q:to/OUTPUT/,
                    1..3
                not ok 2 - this is sub 1
                OUTPUT
                todo-output    => q{},
                failure-output => qq{    # Looks like you failed 2 tests out of 3.\n},
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => "# Looks like you failed 1 test out of 2.\n",
            },
        },
    ],
);

my-diag('Diag from passing, failing, and todo test, in top-level test and subtests');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
                name   => 'will fail',
            },
            expect => ${
                output         => qq{not ok 2 - will fail\n},
                todo-output    => q{},
                failure-output => qq:to/FAILURE/,
                #   Failed test 'will fail'
                #   at $*PROGRAM-NAME line 1381
                FAILURE
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
            event => Test::Stream::Event::Todo::Start,
            args  => ${
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
                todo-output    => qq:to/TODO/,
                #   Failed (TODO) test 'needs fixing'
                #   at $*PROGRAM-NAME line 1381
                TODO
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
            event => Test::Stream::Event::Todo::End,
            args  => ${
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-start',
            args  => ${
                name => 'subtest',
            },
            expect => ${
                output         => "# Subtest subtest\n",
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
                output         => qq{    ok 1 - passed\n},
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
                failure-output => qq{    # diag 1\n},
            },
        },
        ${
            event => Test::Stream::Event::Test,
            args  => ${
                passed => False,
                name   => 'will fail',
            },
            expect => ${
                output         => qq{    not ok 2 - will fail\n},
                todo-output    => q{},
                failure-output => qq:to/FAILURE/,
                    #   Failed test 'will fail'
                    #   at $*PROGRAM-NAME line 1381
                FAILURE
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
                failure-output => qq{    # diag 2\n},
            },
        },
        ${
            event => Test::Stream::Event::Todo::Start,
            args  => ${
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
                output         => qq{    not ok 3 - needs fixing # TODO not yet done\n},
                todo-output    => qq:to/TODO/,
                    #   Failed (TODO) test 'needs fixing'
                    #   at $*PROGRAM-NAME line 1381
                TODO
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
                todo-output    => qq{    # diag 3\n},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo::End,
            args  => ${
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => 'subtest',
            },
            expect => ${
                output         => q:to/OUTPUT/,
                    1..3
                not ok 4 - subtest
                OUTPUT
                todo-output    => q{},
                failure-output => qq{    # Looks like you failed 1 test out of 3.\n},
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => "1..4\n",
                todo-output    => q{},
                failure-output => "# Looks like you failed 2 tests out of 4.\n",
            },
        },
    ],
);

my-diag('Note always go to $.output, whether in todo or not');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Note,
            args  => ${
                message => 'note 1',
            },
            expect => ${
                output         => "# note 1\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo::Start,
            args  => ${
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Note,
            args  => ${
                message => 'note 2',
            },
            expect => ${
                output         => "# note 2\n",
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
                output         => "not ok 1 - needs fixing # TODO not yet done\n",
                todo-output    => qq:to/TODO/,
                #   Failed (TODO) test 'needs fixing'
                #   at $*PROGRAM-NAME line 1381
                TODO
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo::End,
            args  => ${
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-start',
            args  => ${
                name => 'subtest',
            },
            expect => ${
                output         => "# Subtest subtest\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Note,
            args  => ${
                message => 'subnote 1',
            },
            expect => ${
                output         => qq{    # subnote 1\n},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo::Start,
            args  => ${
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Note,
            args  => ${
                message => 'subnote 2',
            },
            expect => ${
                output         => qq{    # subnote 2\n},
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
                output         => qq{    not ok 1 - needs fixing # TODO not yet done\n},
                todo-output    => qq:to/TODO/,
                    #   Failed (TODO) test 'needs fixing'
                    #   at $*PROGRAM-NAME line 1381
                TODO
                failure-output => q{},
            },
        },
        ${
            event => Test::Stream::Event::Todo::End,
            args  => ${
                reason => 'not yet done',
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => 'subtest',
            },
            expect => ${
                output         => qq{    1..1\nok 2 - subtest\n},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => "1..2\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
);

my-diag('Bail out');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
);

my-diag('Bail out in a subtest');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
        ${
            event => 'suite-start',
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
);

my-diag('Skip all');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => q{},
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
);

my-diag('Skip all in a subtest');
test-formatter(
    event-tests => $[
        ${
            event => 'suite-start',
            args  => ${
                name => $*PROGRAM-NAME,
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
            event => 'suite-start',
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
            event => 'suite-end',
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
            event => 'suite-end',
            args  => ${
                name => $*PROGRAM-NAME,
            },
            expect => ${
                output         => "1..3\n",
                todo-output    => q{},
                failure-output => q{},
            },
        },
    ],
);

my-done-testing;

sub test-formatter (:@event-tests) {
    my %outputs = (
        output         => My::IO::String.new,
        todo-output    => My::IO::String.new,
        failure-output => My::IO::String.new,
    );

    my $tap = Test::Stream::Formatter::TAP12.new(|%outputs);
    my $hub = Test::Stream::Hub.new;
    $hub.add-listener($tap);

    for @event-tests -> $test {
        test-event-output(
            $hub,
            $test,
            %outputs,
        );
        $_.clear for %outputs.values;
    }
}

sub test-event-output (
    Test::Stream::Hub:D $hub,
    $test,
    %outputs,
) {
    given $test<event> {
        when 'suite-start' {
            my-lives-ok(
                { $hub.start-suite( |$test<args> ) },
                'sending start-suite to formatter',
            );
        }
        when 'suite-end' {
            my-lives-ok(
                { $hub.end-suite( |$test<args> ) },
                'sending end-suite to formatter',
            );
        }
        default {
            my-lives-ok(
                { $hub.send-event( $test<event>.new( |$test<args> ) ) },
                "sending {$test<event>.^name} to formatter",
            );
        }
    };

    for < output todo-output failure-output > -> $h {
        compare-outputs( $h, %outputs, $test<expect> );
    }
}

sub compare-outputs (Str:D $key, %outputs, %expect) {
    if %expect{$key} ~~ Regex {
        my-like(
            %outputs{$key}, %expect{$key},
            "got expected $key"
        );
    }
    else {
        my-is(
            %outputs{$key}, %expect{$key},
            "got expected $key"
        );
    }
}
