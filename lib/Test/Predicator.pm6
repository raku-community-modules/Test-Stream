use v6;

unit class Test::Predicator;

use Test::Stream::Diagnostic;
use Test::Stream::Event;
use Test::Stream::Hub;
use Test::Stream::Types;

has Test::Stream::Hub:D $.hub is required;
has Bool:D $!manage-top-suite  = True;
has Bool:D $!started-top-suite = False;
has Str:D  $!top-suite-name    = IO::Path.new($*PROGRAM-NAME).basename;

method plan (PositiveInt:D $planned) {
    self!send-event(
        Test::Stream::Event::Plan.new(
            planned => $planned,
        )
    )        
}

method pass ($name? --> Bool:D) {
    self!send-test( True, $name );
    return True;
}

method flunk ($name? --> Bool:D) {
    self!send-test( False, $name );
    return False;
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

# If I juse use "!===" inline in code it works fine, but there is no
# &infix:<!===> unless I make it here.
our sub infix:<!===> ($a, $b --> Bool:D) {
    return !( $a === $b );
}

method isnt (Mu $got, Mu $expected, $name? --> Bool:D) {
    use MONKEY-SEE-NO-EVAL;
    my $op =
        !$got.defined || !$expected.defined
        ?? &infix:<!===>
        !! &infix:<ne>;

    return self!real-cmp-ok( $got, $op, $expected, $name, True );
}

method cmp-ok (Mu $got, $op, Mu $expected, $name? --> Bool:D) {
    use MONKEY-SEE-NO-EVAL;
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

method isa-ok (Mu $got, Mu $type, $name? --> Bool:D) {
    my $passed = $got.isa($type);
    my $thing = description-of($got);
    self!send-test(
        $passed,
        $name // description-of($got) ~ " isa {$type.^name}",
        diagnostic-message => "Expected an object or class which is a {$type.^name} or a subclass",
    );

    return $passed;
}

method does-ok (Mu $got, Mu $role, $name? --> Bool:D) {
    my $description = description-of($got);

    my $passed = ?$got.does($role);
    self!send-test(
        $passed,
        $name // "$description does the role {$role.perl}",
        diagnostic-message => "$description does not do the role {$role.perl}",
    );

    return $passed;
}

method can-ok (Mu $got, Mu $method, $name? --> Bool:D) {
    my $passed = ?$got.^can($method);
    self!send-test(
        $passed,
        $name // description-of($got) ~ " has a method $method",
    );

    return $passed;
}

sub description-of (Mu $got) {
    return $got.defined
        ?? "An object of class {$got.^name}"
        !! 'The ' ~
           ~ ( $got.HOW.^name ~~ /'Class'/ ?? 'class' !! 'role' )
           ~ " {$got.^name}";
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
        $passed,
        $name,
        more => %more,
    );

    return $passed;
}

method is-deeply (Mu $got, Mu $expected, $name) {
    my $passed = $got eqv $expected;
    my %more = (
        got      => $got.perl,
        expected => $expected.perl,
    ) unless $passed;
}

method lives-ok (Callable:D $code, $name?) {
    try {
        $code();
    }

    my $passed = !$!.defined;
    self!send-test(
        $passed,
        $name,
        more => ${ exception => $! },
    );

    return $passed;
}

method dies-ok (Callable:D $code, $name?) {
    my $passed = True;
    try {
        $code();
        $passed = False;
    }

    self!send-test(
        $passed,
        $name,
        diagnostic-message => 'The code ran without throwing an exception',
    );
}

# method throws-like (Callable:D $code, My:U $type?, $name?) {

# }

# XXX - set up context around block?
method subtest (Str:D $name, &block --> Bool:D) {
    $!hub.start-suite(:$name);
    &block();
    my $suite = $!hub.end-suite(:$name);
    return $suite.passed;
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
    );
}

method skip (Str :$reason, PositiveInt:D :$count ) {
    self!send-event(
        Test::Stream::Event::Skip.new(
            count  => $count,
            reason => $reason,
        )
    );
}

method skip-all (Str $reason?) {
    self!send-event(
        Test::Stream::Event::SkipAll.new(
            reason => $reason,
        )
    );
}

method diag (Str:D(Mu:D) $message) {
    self!send-event(
        Test::Stream::Event::Diag.new(
            message => $message,
        )
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
        Test::Stream::Event::Test.new(|%e)
    );
}

method !send-event (Test::Stream::Event:D $event) {
    if $!manage-top-suite && !$!started-top-suite {
        $!hub.start-suite( name => $!top-suite-name );
        $!started-top-suite = True;
    }

    $!hub.send-event($event);
}

submethod DESTROY {
    return unless $!started-top-suite;
    $!hub.end-suite( name => $!top-suite-name );
}
