use v6;
use lib 'lib', 't/lib';;

use IO::String;
use Test::Stream::Event;
use Test::Stream::Formatter::TAP12;

# Note that this test cannot use Test.pm6 (because I hope that module will
# eventually be built on top of Test::Stream), nor any other test
# module. Instead, we'll print raw TAP. Once this test passes other tests can
# safely rely on Test::Stream::TAP12::Formatter.

# Every event we send generates 4 basic tests ...
#    - did it throw an exception?
#    - do each of the 3 output handles contain the expected output?
my $test-count = 4;
say "1..$test-count";

my $test-num = 1;

# No subtests, all tests passing
test-formatter(
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
            output         => "ok 1 test 1\n",
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
            output         => "ok 2 something\n",
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
            output         => rx{
                '# Started at ' \d+ '.' \d+
                ' - ended at ' \d+ '.' \d+
                ' - elapsed time is ' \d+ '.' \d+ "s\n"
            },
            todo-output    => q{},
            failure-output => q{},
        },
    },
);

sub test-formatter (*@tests) {
    my %outputs = (
        output         => IO::String.new,
        todo-output    => IO::String.new,
        failure-output => IO::String.new,
    );

    my $tap = Test::Stream::Formatter::TAP12.new(|%outputs);

    for @tests -> $test {
        test-event-output(
            $tap,
            $test<event>.new( |$test<args> ),
            %outputs,
            $test<expect>,
        );
    }
}

sub test-event-output (
    Test::Stream::Formatter::TAP12:D $tap,
    Test::Stream::Event:D $event,
    %outputs,
    %expect,
) {
    {
        $tap.accept-event($event);
        tap-ok( "no exception sending {$event.type} to formatter" );
        CATCH {
            default {
                tap-not-ok(
                    "no exception sending {$event.type} to formatter",
                    $_.Str.lines.flat,
                    $_.backtrace.Str.lines.flat,
                );
            }
        }
    }

    for < output todo-output failure-output > -> $h {
        if %outputs{$h} ~~ %expect{$h} {
            tap-ok( "got expected $h for {$event.type}" );
        }
        else {
            my $got    = %outputs{$h}.Str.subst( :g, "\n", '\\n' );
            my $expect =
                %expect{$h} ~~ Str
                ?? %expect{$h}.Str.subst( :g, "\n", '\\n' )
                !! %expect{$h}.perl;

            tap-not-ok(
                "got expected $h for {$event.type}",
                qq{      got : "$got"},
                qq{ expected : "$expect"},
            )
        }
    }

    $_.clear for %outputs.values;
}

sub tap-ok (Str:D $name) {
    say 'ok ', $test-num++, " $name";
}

sub tap-not-ok (Str:D $name, *@diag) {
    say q{not ok }, $test-num++, " $name";
    if @diag.elems {
        say q{# }, escape($_) for @diag;
    }
}

sub escape (Str:D $text) {
    return $text.subst( :g, q{#}, Q{\#} ).subst( :g, "\n", "\n#" );
}
