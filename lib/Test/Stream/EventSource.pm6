use v6;

unit class Test::Stream::EventSource;

has CallFrame $.frame handles < code file line >;

method package {
    return $.frame.code.can('package')
        ?? $.frame.code.package
        !! '<none>';
}
