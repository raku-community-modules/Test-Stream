use v6;

use MONKEY-SEE-NO-EVAL;

unit module Test::Predicates;

class Predicator {
    use Test::Stream::Diagnostic;
    use Test::Stream::Event;
    use Test::Stream::Hub;
    use Test::Stream::Types;

    has Bool:D $!send-suite-events = True;
    has Bool:D $!sent-suite-start  = False;
    has Str:D  $!main-suite-name   = IO::Path.new($*PROGRAM-NAME).basename;

    method instance ($class: |c) {
        state $instance //= $class.new(|c);
    }

    method ok (Bool(Any) $passed, $name?) {
        self.send-test( $passed, $name );
        return $passed;
    }

    method is (Mu $got, Mu $expected, $name?) {
        my $op =
            !$got.defined || !$expected.defined
            ?? &infix:<===>
            !! &infix:<eq>;

        return self!real-cmp-ok( $got, $op, $expected, $name, False );
    }

    method isnt (Mu $got, Mu $expected, $name?) {
        my $op =
            !$got.defined || !$expected.defined
            # There is no &infix:<!===>, but this somehow gets turned into a
            # Callable via some sort of magic I do not understand.
            ?? EVAL('&infix:<!===>')
            !! &infix:<ne>;

        return self!real-cmp-ok( $got, $op, $expected, $name, True );
    }

    method cmp-ok (Mu $got, $op, Mu $expected, $name?) {
        unless $op ~~ Callable {
            $op = EVAL "&infix:<$op>";
            CATCH {
                default {
                    self.send-test(
                        False,
                        $name,
                        diagnostic-message => qq{Could not use '$op' as a comparator},
                    );
                    return;
                }
            }
        }
        self!real-cmp-ok( $got, $op, $expected, $name, True );
    }

    method !real-cmp-ok (Mu $got, Callable:D $op, Mu $expected, $name, Bool:D $diag-operator) {
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

        self.send-test(
            $passed,
            $name,
            more => %more,
        );

        return $passed;
    }

    # XXX - set up context around block?
    method subtest ($name, &block) {
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

    method skip ($reason, $count = 1) {
        Test::Stream::Hub.instance.send-event(
            Test::Stream::Event::Skip.new(
                count  => $count,
                reason => $reason,
            )
        );
    }

    method diag (Str:D(Mu:D) $message) {
        Test::Stream::Hub.instance.send-event(
            Test::Stream::Event::Diag.new(
                message => $message,
            )
        )
    }

    method disable-suite-events {
        if $!sent-suite-start {
            die 'Too late to disable the suite events as the Suite::Start event has already been sent';
        }

        $!send-suite-events = False;
    }

    method send-test (Bool:D $passed, $name, :$diagnostic-message?, :%more?) {
        if $!send-suite-events && !$!sent-suite-start {
            Test::Stream::Hub.instance.send-event(
                Test::Stream::Event::Suite::Start.new( name => $!main-suite-name )
            );
            $!sent-suite-start = True;
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

    submethod DESTROY {
        return unless $!sent-suite-start;
        Test::Stream::Hub.instance.send-event(
            Test::Stream::Event::Suite::End.new( name => $!main-suite-name )
        );
    }
}

sub ok (|c) is export {
    Predicator.instance.ok(|c);
}

sub is (|c) is export {
    Predicator.instance.is(|c);
}

sub isnt (|c) is export {
    Predicator.instance.isnt(|c);
}

sub cmp-ok (|c) is export {
    Predicator.instance.cmp-ok(|c);
}

multi sub subtest (&block, $name?) is export {
    Predicator.instance.subtest( $name, &block );
}

multi sub subtest (Str:D $name, &block) is export {
    Predicator.instance.subtest( $name, &block );
}

multi sub skip () is export {
    Predicator.instance.skip( q{}, 1 );
}

multi sub skip ($reason, $count = 1) is export {
    Predicator.instance.skip( $reason, $count );
}

sub diag (|c) {
    Predicator.instance.diag(|c);
}
