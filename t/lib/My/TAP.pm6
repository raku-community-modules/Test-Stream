unit module My::TAP;

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

sub my-ok (Bool:D $ok, Str:D $name, *@diag) is export {
    state $test-num = 1;

    my $start = $ok ?? q{} !! q{not };
    say $start, q{ok - }, $test-num++, " $name";
    unless $ok {
        my-diag($_) for @diag.values 
    }
    return $ok;
}

sub my-diag (Str:D $message) is export {
    $*ERR.say( q{# }, escape($message) );
}

sub escape (Str:D $text) {
    return $text.subst( :g, q{#}, Q{\#} ).subst( :g, "\n", "\n#" );
}
