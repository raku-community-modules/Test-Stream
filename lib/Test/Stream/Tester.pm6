use v6;

unit module Test::Stream::Tester;

use Test::Predicates;
use Test::Stream::Hub;
use Test::Stream::Recorder;

sub test-event-stream (Test::Stream::Recorder:D $recorder, *@expect) is export {
    my @got = $recorder.events;
    is(
        @got.elems,
        @expect.elems,
        'got the expected number of events',
    ) or diag("got {@got.elems}, expected {@expect.elems}");

    my $i = 0;
    for @got Z @expect -> ($g, $e) {
        my $class = $e<class>;
        subtest(
            "event[{$i++}]", {
                is(
                    $g.WHAT,
                    $class,
                    "got a {$class.^name} event",
                );

                test-event-attributes( $g, $e );
            }
        );
    }

    $recorder.clear;
}

my sub test-event-attributes ($g, $e) {
    for $e<attributes>.keys -> $k {
        ok(
            ?$g.can($k),
            "event has a $k method",
        ) or return;

        if $e<attributes>{$k} ~~ Test::Stream::Diagnostic {
            test-diagnostic( $g."$k"(), $e<attributes>{$k}, $k );
        }
        else {
            is-deeply(
                $g."$k"(),
                $e<attributes>{$k},
                "event has the expected $k attribute",
            );
        }
    }
}

my sub test-diagnostic ($g-diag, $e-diag, $k) {
    isa-ok(
        $g-diag,
        Test::Stream::Diagnostic,
        "$k attribute",
    ) or return;

    is(
        $g-diag.defined,
        $e-diag.defined,
        "$k is defined or not as expected",
    );

    return unless $g-diag.defined && $e-diag.defined;

    is(
        $g-diag.severity,
        $e-diag.severity,
        "$k.severity",
    );
    is(
        $g-diag.message,
        $e-diag.message,
        "$k.message",
    );

    # This doesn't seem to get compared properly by is-deeply so we do
    # our own comparison and remove it from the hash so the rest can
    # be passed to is-deeply.
    if $e-diag.more<operator>:exists {
        my $g-op = $g-diag.more<operator>:delete;
        my $e-op = $e-diag.more<operator>:delete;
        is(
            $g-op.perl,
            $e-op.perl,
            "$k.more<operator>",
        );
    }

    is-deeply(
        $g-diag.more,
        $e-diag.more,
        "$k.more",
    );
}
