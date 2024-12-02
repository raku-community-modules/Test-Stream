use v6;

# Copied from hoelzro's IO::String distro. It's probably best for this distro
# to _not_ rely on external modules.

class My::IO::String:ver<0.1.0>:auth<hoelzro> is IO::Handle {
    has @.contents;

    method print(*@what) {
        @.contents.push: @what.join('');
    }

    method print-nl {
        self.print($.nl-out);
    }

    method clear {
        @.contents = ();
    }

    #| Returns, as a string, everything that's been written to
    #| this object.
    method Str { @.contents.join('') }
}
