use v6;

unit class Test::Stream::EventSource;

has $.file;
has $.line;
has $.package;
has Int:D $.pid = $*PID;
has Int:D $.tid = $*THREAD.id;

method from-frame ($class: CallFrame:D $frame) {
    my %args = (
        file => $frame.file,
        line => $frame.line,
    );
    %args<package> = $frame.code.package if $frame.code.can('package');

    return $class.new(|%args);
}
