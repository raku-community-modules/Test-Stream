unit module My::TAP;

use My::Listener;

sub my-lives-ok (Code $code, Str:D $name) is export {
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

sub my-throws-ok (Code $code, Str:D $name) is export {
    $code();

    my-ok( False, "got exception from $name" );
    CATCH {
        default {
            my-ok(
                True,
                "got exception from $name",
            );
            return $_;
        }
    }

    return;
}

my $test-num = 1;
sub my-ok ($ok, Str:D $name, *@diag) is export {
    my $start = ?$ok ?? q{} !! q{not };
    say $start, q{ok }, $test-num++, " - $name";
    unless $ok {
        my-diag($_) for @diag.values;
    }
    return $ok;
}

sub my-diag (Str:D $message) is export {
    $*ERR.say( q{# }, escape($message) );
}

sub escape (Str:D $text) {
    return $text.subst( :g, q{#}, Q{\#} ).subst( :g, "\n", "\n#" );
}

sub test-event-stream (My::Listener $listener, *@expect) is export {
    my @got = $listener.events;
    my-ok(
        @got.elems == @expect.elems,
        'got the expected number of events'
    ) or my-diag("got {@got.elems}, expected {@expect.elems}");

    for @got Z @expect -> ($g, $e) {
        my $class = $e<class>;
        my-ok(
            $g.WHAT === $class,
            "got a {$class.^name} event"
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
            my ($o, $d);
            if !$g.defined {
                $o = False;
                $d = 'diagnostic is not defined';
            }
            elsif $g !~~ Test::Stream::Diagnostic {
                $o = False;
                $d = 'diagnostic is not a Test::Stream::Diagnostic object';
            }
            elsif ( $g.severity.defined != $e.severity.defined )
                  || ( $g.severity != $e.severity ) {
                $o = False;
                $d = "diagnostic.severity - got: {stringify($g.severity)}, expected: {stringify($e.severity)}";
            }
            elsif ( $g.message.defined != $e.message.defined )
                  || ( $g.message.defined && $e.message.defined && $g.message ne $e.message ) {
                $o = False;
                $d = "diagnostic.message - got: {stringify($g.message)}, expected: {stringify($e.message)}";
            }
            else {
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
