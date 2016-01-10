use v6;

use MONKEY-SEE-NO-EVAL;

unit module Test::Predicates;

class Predicator {
    use Test::Stream::Diagnostic;
    use Test::Stream::Event;
    use Test::Stream::Hub;
    use Test::Stream::Types;

    has Test::Stream::Hub:D $!hub is required;
    has Bool:D $!manage-top-suite  = True;
    has Bool:D $!started-top-suite = False;
    has Str:D  $!top-suite-name    = IO::Path.new($*PROGRAM-NAME).basename;

    submethod BUILD (:$!hub) { }

    method instance ($class: *%args) {
        %args<hub> //= Test::Stream::Hub.instance;
        state $instance //= $class.new(|%args);
    }

    method plan (PositiveInt:D $planned) {
        self!send-event(
            Test::Stream::Event::Plan,
            planned => $planned,
        )        
    }

    method ok (Bool:D(Any) $passed, $name? --> Bool:D) {
        self!send-test( $passed, $name );
        return $passed;
    }

    method is (Mu $got, Mu $expected, $name? --> Bool:D) {
        my $op =
            !$got.defined || !$expected.defined
            ?? &infix:<===>
            !! &infix:<eq>;

        return self!real-cmp-ok( $got, $op, $expected, $name, False );
    }

    method isnt (Mu $got, Mu $expected, $name? --> Bool:D) {
        my $op =
            !$got.defined || !$expected.defined
            # There is no &infix:<!===>, but this somehow gets turned into a
            # Callable via some sort of magic I do not understand.
            ?? EVAL('&infix:<!===>')
            !! &infix:<ne>;

        return self!real-cmp-ok( $got, $op, $expected, $name, True );
    }

    method cmp-ok (Mu $got, $op, Mu $expected, $name? --> Bool:D) {
        # Note that we have to use «» in order to make sure that < and > work.
        if $op ~~ Callable ?? $op !! try EVAL qq{&infix:«$op»} -> $matcher {
            return self!real-cmp-ok( $got, $matcher, $expected, $name, True );
        }

        self!send-test(
            False,
            $name,
            diagnostic-message => qq{Could not use '$op' as a comparator},
        );

        return False;
    }

    method !real-cmp-ok (Mu $got, Callable:D $op, Mu $expected, $name, Bool:D $diag-operator --> Bool:D) {
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

        self!send-test(
            $passed,
            $name,
            more => %more,
        );

        return $passed;
    }

    # XXX - set up context around block?
    method subtest (Str:D $name, Callable:D $block --> Bool:D) {
        $!hub.start-suite(:$name);
        $block();
        my $suite = $!hub.end-suite(:$name);
        return $suite.passed;
    }

    method skip (Str :$reason, PositiveInt:D :$count ) {
        self!send-event(
            Test::Stream::Event::Skip,
            count  => $count,
            reason => $reason,
        );
    }

    method skip-all (Str $reason) {
        self!send-event(
            Test::Stream::Event::SkipAll,
            reason => $reason,
        );
    }

    method diag (Str:D(Mu:D) $message) {
        self!send-event(
            Test::Stream::Event::Diag,
            message => $message,
        )
    }

    method !send-test (Bool:D $passed, $name, :$diagnostic-message?, :%more?) {
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

        self!send-event(
            Test::Stream::Event::Test,
            |%e,
        );
    }

    method !send-event (|c) {
        if $!manage-top-suite && !$!started-top-suite {
            $!hub.start-suite( name => $!top-suite-name );
            $!started-top-suite = True;
        }

        $!hub.send-event(|c);
    }

    submethod DESTROY {
        return unless $!started-top-suite;
        $!hub.end-suite( name => $!top-suite-name );
    }
}

sub plan (|c) is export {
    Predicator.instance.plan(|c);
}

sub ok (|c --> Bool:D) is export {
    return Predicator.instance.ok(|c);
}

sub is (|c --> Bool:D)  is export {
    return Predicator.instance.is(|c);
}

sub isnt (|c --> Bool:D)  is export {
    return Predicator.instance.isnt(|c);
}

sub cmp-ok (|c --> Bool:D)  is export {
    return Predicator.instance.cmp-ok(|c);
}

sub subtest (Str:D $name, &block --> Bool:D) is export {
    return Predicator.instance.subtest( $name, &block );
}

multi sub skip () is export {
    Predicator.instance.skip( :count(1) );
}

multi sub skip ($reason, $count = 1) is export {
    Predicator.instance.skip(
        reason => $reason // (Str),
        :$count,
    );
}

sub skip-all ($reason?) is export {
    Predicator.instance.skip-all( $reason // (Str) );
}

sub diag (|c) is export {
    Predicator.instance.diag(|c);
}
