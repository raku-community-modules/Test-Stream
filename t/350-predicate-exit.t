use v6;
use lib 'lib', 't/lib';

use My::Test;

my %scripts = (
    'plan-exit-ok.pl6' => ${
        out => Q:to/END/,
        1..2
        ok 1 - test 1
        ok 2
        END
        exit-code => 0,
    },
    'no-plan-exit-ok.pl6' => ${
        out => Q:to/END/,
        ok 1 - test 1
        ok 2
        1..2
        END
        exit-code => 0,
    },
    'test-failures.pl6' => ${
        out => Q:to/END/,
        ok 1 - test 1
        not ok 2
        1..2
        # failed 1 test
        END
        err => Q:to/END/,
        #   Failed test
        #   at /home/autarch/projects/perl6/Test-Stream/lib/Test/Predicator.pm6 line 331
        # Looks like you failed 1 test out of 2.
        END
        exit-code => 1,
    },
    'bail.pl6' => ${
        out => Q:to/END/,
        ok 1 - test 1
        Bail out!  things are going wrong
        END
        exit-code => 255,
    },
);

for %scripts.kv -> $script, $expect {
    my $path = $*SPEC.catfile( $*PROGRAM.dirname, 'helpers', $script );
    # We'd prefer to test the merged stdout & stderr but the :merge arg causes
    # a segfault - https://rt.perl.org/Ticket/Display.html?id=125756
    my $proc = run( $*EXECUTABLE, $path, :out, :err );
    my-is( $proc.out.slurp-rest, $expect<out>, "got expected stdout from $script" );
    my-is( $proc.err.slurp-rest, $expect<err> // q{}, "got expected stderr from $script" );
    # We need to close the handles in order to get the exitcode - the try
    # block is for https://rt.perl.org/Ticket/Display.html?id=125757
    try {
        $proc.out.close;
        $proc.err.close;
    }
    my-is( $proc.exitcode, $expect<exit-code>, "exit code is $expect<exit-code>" );
}

my-done-testing();
