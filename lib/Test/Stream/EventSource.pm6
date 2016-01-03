use v6;

unit class Test::Stream::EventSource;

# It might make more sense to use Callframe, but this is completely
# undocumented and doesn't have any methods to tell you if the frame is from
# the setting or other code that should be skipped.
has Backtrace::Frame $.frame handles < code file line >;
has Int:D $.pid = $*PID;
has Int:D $.tid = $*THREAD.id;

submethod BUILD {
    for Backtrace.new.values -> $frame {
        next if $frame.is-hidden;
        next if $frame.is-setting;
        next if $frame.code.can('package')
            && $frame.code.package.^name ~~ rx{ 'Test::Stream' };

        $!frame = $frame;
        last;
    }
}

method package {
    return $.frame.code.can('package')
        ?? $.frame.code.package
        !! '<none>';
}
