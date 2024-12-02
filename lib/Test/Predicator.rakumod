unit class Test::Predicator;

use Test::Stream::Diagnostic;
use Test::Stream::Event;
use Test::Stream::Hub;
use Test::Stream::Types;

has Test::Stream::Hub:D $.hub is required;
has Bool:D $!manage-top-suite  = True;
has Bool:D $!started-top-suite = False;
has Str:D  $!top-suite-name    = IO::Path.new($*PROGRAM-NAME).basename;

submethod BUILD (
    Test::Stream::Hub:D :$!hub,
    Bool:D :$!manage-top-suite = True,
) { }

method plan (PositiveInt:D $planned) {
    self!send-event(
        Test::Stream::Event::Plan.new(
            planned => $planned,
        )
    )        
}

method pass ($name? --> True) {
    self!send-test( True, $name )
}

method flunk ($name? --> False) {
    self!send-test( False, $name )
}

method ok (Bool(Any) $passed, $name? --> Bool:D) {
    self!send-test( $passed, $name );
    $passed
}

method is (Mu $got, Mu $expected, $name? --> Bool:D) {
    my $op =
        !$got.defined || !$expected.defined
        ?? &infix:<===>
        !! &infix:<eq>;

    self!real-cmp-ok( $got, $op, $expected, $name, False )
}

# If I juse use "!===" inline in code it works fine, but there is no
# &infix:<!===> unless I make it here.
our sub infix:<!===> ($a, $b --> Bool:D) {
    !( $a === $b );
}

method isnt (Mu $got, Mu $expected, $name? --> Bool:D) {
    my $op =
        !$got.defined || !$expected.defined
        ?? &infix:<!===>
        !! &infix:<ne>;

    self!real-cmp-ok( $got, $op, $expected, $name, True )
}

method cmp-ok (Mu $got, $op, Mu $expected, $name? --> Bool:D) {
    my $matcher = $op;
    unless $matcher ~~ Callable {
        # We may have to use «» in order to make sure that '<' and '>' can be
        # passed as ops.
        my @delims = $op ~~ rx{ <[ < > ]> } ?? ( '«', '»' ) !! ( '<', '>' );
        use MONKEY-SEE-NO-EVAL;
        # The "\&" bit is needed because of
        # https://rt.perl.org/Ticket/Display.html?id=127284
        $matcher = EVAL qq{\&infix:@delims[0]$op@delims[1]};
        CATCH {
            self!send-test(
                False,
                $name,
                diagnostic-message => qq{Could not use '$op' as a comparator},
            );
            return False;
        }
    }

    self!real-cmp-ok( $got, $matcher, $expected, $name, True )
}

method isa-ok (Mu $got, Mu $type, $name? --> Bool:D) {
    my $passed = $got.isa($type);
    my $thing = description-of($got);
    self!send-test(
        $passed,
        $name // description-of($got) ~ " isa {$type.^name}",
        diagnostic-message => "Expected an object or class which is a {$type.^name} or a subclass",
    );

    $passed
}

method does-ok (Mu $got, Mu $role, $name? --> Bool:D) {
    my $description = description-of($got);

    my $passed = ?$got.does($role);
    self!send-test(
        $passed,
        $name // "$description does the role {$role.perl}",
        diagnostic-message => "$description does not do the role {$role.perl}",
    );

    $passed
}

method can-ok (Mu $got, Mu $method, $name? --> Bool:D) {
    my $passed = ?$got.^can($method);
    self!send-test(
        $passed,
        $name // description-of($got) ~ " has a method $method",
    );

    $passed
}

sub description-of (Mu $got) {
    $got.defined
        ?? "An object of class {$got.^name}"
        !! 'The ' ~
           ~ ( $got.HOW.^name ~~ /'Class'/ ?? 'class' !! 'role' )
           ~ " {$got.^name}"
}

method like (Str $got, Regex:D $regex, $name? --> Bool:D) {
    self!real-cmp-ok( $got, &infix:<~~>, $regex, $name, True )
}

method unlike (Str $got, Regex:D $regex, $name? --> Bool:D) {
    self!real-cmp-ok( $got, &infix:<!~~>, $regex, $name, True )
}

method !real-cmp-ok (Mu $got, Callable:D $op, Mu $expected, $name, Bool:D $diag-operator --> Bool:D) {
    my $passed = $op( $got, $expected );

    my %more;
    unless $passed {
        %more = (
            got      => $got,
            expected => $expected,
        );
        %more<operator> = $op
            if $diag-operator;
    }

    self!send-test(
        so $passed,
        $name,
        more => %more,
    );

    $passed.Bool
}

method is-deeply (Mu $got, Mu $expected, $name? --> Bool:D) {
    my $passed = $got eqv $expected;
    my %more = (
        got      => $got.perl,
        expected => $expected.perl,
        operator => &infix:<eqv>,
    ) unless $passed;

    self!send-test(
        $passed,
        $name,
        more => %more,
    );

    $passed
}

method lives-ok (&block, $name? --> Bool:D) {
    try {
        &block();
    }

    my $passed = !$!.defined;
    self!send-test(
        $passed,
        $name,
        more => ${ exception => $! },
    );

    $passed
}

method dies-ok (&block, $name? --> Bool:D) {
    my $passed = True;
    try {
        &block();
        $passed = False;
    }

    self!send-test(
        $passed,
        $name,
        diagnostic-message => 'The code ran without throwing an exception',
    );

    $passed
}

multi method throws-like (&block, Mu:U $type, $name? --> Bool:D) {
    self.subtest(
        $name // "throws-like {$type.^name}", {
            my $passed = True;
            try {
                &block();
                $passed = False;
            }
            my $e = $!;

            self.ok( $passed, 'code throws an exception' );
            if $e.defined {
                self.isa-ok( $e, $type, "exception thrown by code isa {$type.^name}" );
            }
        },
    )
}

multi method throws-like (&block, Regex:D $regex, $name? --> Bool:D) {
    self.subtest(
        $name // "throws-like message content", {
            my $passed = True;
            try {
                &block();
                $passed = False;
            }
            my $e = $!;

            self.ok( $passed, 'code throws an exception' );
            if $e.defined {
                self.like( $e.message, $regex );
            }
        },
    )
}

# XXX - set up context around block?
method subtest (Str:D $name, &block --> Bool:D) {
    $!hub.start-suite(:$name);
    &block();
    my $suite = $!hub.end-suite(:$name);
    $suite.passed
}

method todo (Str:D $reason, &block) {
    self!send-event(
        Test::Stream::Event::Todo::Start.new(
            reason => $reason,
        )
    );
    &block();
    self!send-event(
        Test::Stream::Event::Todo::End.new(
            reason => $reason,
        )
    )
}

method skip (Str :$reason, PositiveInt:D :$count ) {
    self!send-event(
        Test::Stream::Event::Skip.new(
            count  => $count,
            reason => $reason,
        )
    )
}

method skip-all (Str $reason?) {
    self!send-event(
        Test::Stream::Event::SkipAll.new(
            reason => $reason,
        )
    )
}

method diag (Str:D(Mu:D) $message) {
    self!send-event(
        Test::Stream::Event::Diag.new(
            message => $message,
        )
    )
}

method bail ($reason?) {
    self!send-event(
        Test::Stream::Event::Bail.new(
            reason => $reason,
        )
    )
}

method done-testing {
    unless $!hub.main-suite.tests-planned {
        self.plan( $!hub.main-suite.tests-run );
    }

    $!hub.end-suite( name => $!top-suite-name );

    $!hub.finalize
}

method !send-test (Bool:D $passed, $name, :$diagnostic-message?, :%more?) {
    my %e = (:$passed);
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
        Test::Stream::Event::Test.new(|%e)
    )
}

method !send-event (Test::Stream::Event:D $event) {
    if $!manage-top-suite && !$!started-top-suite {
        $!hub.start-suite( name => $!top-suite-name );
        $!started-top-suite = True;
    }

    $!hub.send-event($event)
}

submethod DESTROY {
    return unless $!started-top-suite;
    $!hub.end-suite( name => $!top-suite-name );
}

# vim: expandtab shiftwidth=4
