use v6;

unit class Test::Stream::EventSource;

has CallFrame $.frame handles < code file line >;
has Int:D $.pid = $*PID;
has Int:D $.tid = $*THREAD.id;

method package {
    return $.frame.code.can('package')
        ?? $.frame.code.package
        !! '<none>';
}
