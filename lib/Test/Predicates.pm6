use v6;

use MONKEY-SEE-NO-EVAL;

unit module Test::Predicates;

use Test::Stream::Diagnostic;
use Test::Stream::Event;
use Test::Stream::Hub;
use Test::Stream::Types;

sub ok (Bool(Any) $passed, $name?) is export {
    send-test( $passed, $name );
    return $passed;
}

sub is(Mu $got, Mu $expected, $name?) is export {
    my $op = 
        !$got.defined || !$expected.defined
        ?? &infix:<===>
        !! &infix:<eq>;

    return real-cmp-ok( $got, $op, $expected, $name, False );
}

sub isnt(Mu $got, Mu $expected, $name?) is export {
    my $op = 
        !$got.defined || !$expected.defined
        # There is no &infix:<!===>, but this somehow gets turned into a
        # Callable via some sort of magic I do not understand.
        ?? EVAL('&infix:<!===>')
        !! &infix:<ne>;

    return real-cmp-ok( $got, $op, $expected, $name, True );
}

sub cmp-ok(Mu $got, $op, Mu $expected, $name?) is export {
    unless $op ~~ Callable {
        $op = EVAL "&infix:<$op>";
        CATCH {
            default {
                send-test(
                    False,
                    $name,
                    diagnostic-message => qq{Could not use '$op' as a comparator},
                );
                return;
            }
        }
    }
    real-cmp-ok( $got, $op, $expected, $name, True );
}

sub real-cmp-ok(Mu $got, Callable:D $op, Mu $expected, $name, Bool:D $diag-operator) {
    my %more;

    my $passed = $op( $got, $expected );
    unless $passed {
        %more = (
            got      => $got,
            expected => $expected,
        );
        %more<operator> = $op
            if $diag-operator;
    }

    send-test(
        $passed,
        $name,
        more => %more,
    );

    return $passed;
}

multi sub subtest(&block, $name?) is export {
    run-subtest( $name, &block );
}

multi sub subtest(Str:D $name, &block) is export {
    run-subtest( $name, &block );
}

# XXX - set up context around block?
sub run-subtest($name, &block) {
    Test::Stream::Hub.instance.send-event(
        Test::Stream::Event::Suite::Start.new(
            ( $name.defined ?? ( name => $name ) !! () ),
        )
    );

    block();

    Test::Stream::Hub.instance.send-event(
        Test::Stream::Event::Suite::End.new(
            ( $name.defined ?? ( name => $name ) !! () ),
        )
    );
}

multi sub skip($reason, $count = 1) is export {
    Test::Stream::Hub.instance.send-event(
        Test::Stream::Event::Skip.new(
            count  => $count,
            reason => $reason,
        )
    );
}

sub diag(Str:D(Mu:D) $message) is export {
    Test::Stream::Hub.instance.send-event(
        Test::Stream::Event::Diag.new(
            message => $message,
        )
    )
}

my $send-suite-events = True;
my $sent-suite-start = False;
sub disable-suite-events {
    if $sent-suite-start {
        die 'Too late to disable the suite events as the Suite::Start event has already been sent';
    }

    $send-suite-events = False;
}

sub send-test (Bool:D $passed, $name, :$diagnostic-message?, :%more?) {
    if $send-suite-events && !$sent-suite-start {
        Test::Stream::Hub.instance.send-event(
            Test::Stream::Event::Suite::Start.new( name => IO::Path.new($*PROGRAM-NAME).basename )
        );
        $sent-suite-start = True;
    }

    my %e = ( passed => $passed );
    %e<name> = $name if $name.defined;

    unless %e<passed> {
        if $diagnostic-message.defined || %more.keys {
            my %d = ( severity => DiagnosticSeverity::failure );
            %d<message> = $diagnostic-message if $diagnostic-message.defined;
            %d<more>    = %more if %more.keys;

            %e<diagnostic> = Test::Stream::Diagnostic.new(|%d);
        }
    }
    Test::Stream::Hub.instance.send-event(
        Test::Stream::Event::Test.new(|%e)
    );
}

END {
    if $sent-suite-start {
        Test::Stream::Hub.instance.send-event(
            Test::Stream::Event::Suite::End.new( name => IO::Path.new($*PROGRAM-NAME).basename )
        )
    }
}
