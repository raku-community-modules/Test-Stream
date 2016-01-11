use v6;
use lib 'lib', 't/lib';

use My::Test;
use Test::Stream::Event;
use Test::Stream::Suite;

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );

    $suite.accept-event( Test::Stream::Event::Plan.new( planned => 5 ) );
    my-is(
        $suite.tests-planned, 5,
        'tests-planned is set from Plan event'
    );

    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    my-is(
        $suite.tests-run, 1,
        'tests-run is incremented from Test event'
    );
    my-is(
        $suite.tests-failed, 0,
        'tests-failed is still 0 after passing Test event'
    );

    $suite.accept-event( Test::Stream::Event::Test.new( passed => False ) );
    my-is(
        $suite.tests-run, 2,
        'tests-run is incremented from Test event'
    );
    my-is(
        $suite.tests-failed, 1,
        'tests-failed is 1 after failing Test event'
    );

    $suite.accept-event( Test::Stream::Event::Todo::Start.new( reason => 'todo' ) );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    my-is(
        $suite.tests-run, 3,
        'tests-run is incremented from Test event in Todo'
    );
    my-is(
        $suite.tests-failed, 1,
        'tests-failed is still 1 after passing Test event in Todo'
    );

    $suite.accept-event( Test::Stream::Event::Test.new( passed => False ) );
    my-is(
        $suite.tests-run, 4,
        'tests-run is incremented from Test event in Todo'
    );
    my-is(
        $suite.tests-failed, 1,
        'tests-failed is still 1 after failing Test event in Todo'
    );

    $suite.accept-event( Test::Stream::Event::Suite::Start.new( name => 'subtest' ) );
    $suite.accept-event( Test::Stream::Event::Plan.new( planned => 2 ) );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => False ) );
    my-is(
        $suite.tests-planned, 5,
        'tests-planned is unaffected by Plan in sub-Suite'
    );
    my-is(
        $suite.tests-run, 4,
        'tests-run is unaffected by Plan in sub-Suite'
    );
    my-is(
        $suite.tests-failed, 1,
        'tests-failed is unaffected by Plan in sub-Suite'
    );

    $suite.accept-event(
        Test::Stream::Event::Suite::End.new(
            name => 'subtest',
            tests-planned => 2,
            tests-run     => 2,
            tests-failed  => 1,
            passed        => False,
        )
    );
    my-is(
        $suite.tests-run, 5,
        'tests-run is incremented by Suite::End'
    );
    my-is(
        $suite.tests-failed, 2,
        'tests-failed is incremented by failed Suite::End'
    );

    my-is(
        $suite.passed, False,
        'suite did not pass because of tests-failed'
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    my-is(
        $suite.passed, False,
        'suite.passed is false when no tests have been run or planned'
    );

    $suite.accept-event( Test::Stream::Event::Plan.new( planned => 1 ) );
    my-is(
        $suite.passed, False,
        'suite.passed is false when tests planned < tests run'
    );

    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    my-is(
        $suite.passed, True,
        'suite.passed is true when tests planned matches tests run and all tests passed'
    );

    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    my-is(
        $suite.passed, False,
        'suite.passed is false when tests planned > tests run, even if all tests passed'
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    $suite.accept-event( Test::Stream::Event::Skip.new( count => 4 ) );
    my-is(
        $suite.tests-run, 5,
        'tests-run is incremented by Skip event'
    );
    my-is(
        $suite.tests-failed, 0,
        'tests-failed is not affected by Skip event'
    );
    my-is(
        $suite.passed, True,
        'suite.passed is true with skipped tests',
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    $suite.accept-event( Test::Stream::Event::SkipAll.new( reason => 'because' ) );
    my-is(
        $suite.tests-planned, 0,
        'tests-planned is 0 when SkipAll event is sent',
    );
    my-is(
        $suite.tests-failed, 0,
        'tests-failed is 0 when SkipAll event is sent',
    );
    my-is(
        $suite.passed, True,
        'suite.passed is true when SkipAll event is sent and no tests are run',
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    my-throws-like(
        { $suite.accept-event( Test::Stream::Event::SkipAll.new( reason => 'because' ) ) },
        rx{ 'Received a SkipAll event but the current suite has already run 1 test' },
        'got the expected exception when a SkipAll comes after running tests'
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    $suite.accept-event( Test::Stream::Event::Suite::Start.new( name => 'sub' ) );
    my-lives-ok(
        { $suite.accept-event( Test::Stream::Event::SkipAll.new( reason => 'because' ) ) },
        'SkipAll in a child suite does not cause an error',
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    $suite.accept-event( Test::Stream::Event::Todo::Start.new( reason => 'todo1' ) );
    my-throws-like(
        { $suite.accept-event( Test::Stream::Event::Todo::End.new( reason => 'todo2' ) ) },
        rx{
            'Received a Todo::End event with a reason of "todo2" but the'
            ' most recent Todo::Start reason was "todo1"'
        },
        'got the expected exception when a Todo::End does not match Todo::Start',
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    my-throws-like(
        { $suite.accept-event( Test::Stream::Event::Todo::End.new( reason => 'todo' ) ) },
        rx{
            'Received a Todo::End event with a reason of "todo" but'
            ' there is no corresponding Todo::Start event'
        },
        'got the expected exception with Todo::End before Todo::Start',
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    $suite.accept-event( Test::Stream::Event::Skip.new( count => 4 ) );
    my-is(
        $suite.tests-run, 4,
        'tests-run is incremented by Skip event'
    );
    my-is(
        $suite.tests-failed, 0,
        'tests-failed is not affected by Skip event'
    );
    my-is(
        $suite.passed, True,
        'suite.passed is true with _only_ skipped tests',
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    $suite.accept-event( Test::Stream::Event::Plan.new( planned => 2 ) );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => False ) );
    my-is(
        $suite.passed, False,
        'suite.passed is false when any tests failed (with plan)'
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => False ) );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    my-is(
        $suite.passed, False,
        'suite.passed is false when there any tests failed (no plan)'
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    $suite.accept-event( Test::Stream::Event::Test.new( passed => True ) );
    my-is(
        $suite.passed, True,
        'suite.passed is true when all tests pass and there is no plan'
    );
}

{
    my $suite = Test::Stream::Suite.new( name => 'suite' );

    $suite.accept-event( Test::Stream::Event::Test.new( name => '1', passed => True ) );
    $suite.accept-event( Test::Stream::Event::Test.new( name => '2', passed => False ) );

    $suite.accept-event( Test::Stream::Event::Suite::Start.new( name => 'depth 1' ) );
    $suite.accept-event( Test::Stream::Event::Test.new( name => '1.1', passed => True ) );
    $suite.accept-event( Test::Stream::Event::Test.new( name => '1.2', passed => False ) );

    $suite.accept-event( Test::Stream::Event::Suite::Start.new( name => 'depth 2' ) );
    $suite.accept-event( Test::Stream::Event::Test.new( name => '1.1.1', passed => True ) );
    $suite.accept-event( Test::Stream::Event::Test.new( name => '1.1.2', passed => False ) );
    $suite.accept-event(
        Test::Stream::Event::Suite::End.new(
            name          => 'depth 2',
            tests-planned => (Int),
            tests-run     => 2,
            tests-failed  => 1,
            passed        => False,
        )
    );

    $suite.accept-event( Test::Stream::Event::Test.new( name => '1.3', passed => True ) );
    $suite.accept-event( Test::Stream::Event::Test.new( name => '1.4', passed => False ) );

    $suite.accept-event(
        Test::Stream::Event::Suite::End.new(
            name          => 'depth 1',
            tests-planned => (Int),
            tests-run     => 2,
            tests-failed  => 1,
            passed        => False,
        )
    );

    $suite.accept-event( Test::Stream::Event::Test.new( name => '3', passed => True ) );
    $suite.accept-event( Test::Stream::Event::Test.new( name => '4', passed => False ) );

    my-is(
        $suite.tests-run, 5,
        'suite.tests-run counts all test run in the suite itself plus one for a child subtest',
    ) or my-diag($suite.tests-run.Str);
    my-is(
        $suite.tests-failed, 3,
        'suite.tests-failed counts all test run in the suite itself plus one for a child subtest',
    ) or my-diag($suite.tests-failed.Str);
}

my-done-testing;
