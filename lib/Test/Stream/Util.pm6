use v6;

unit package Test::Stream::Util;

# We know that that the nouns we're dealing with are all simple "add an 's'"
# nouns for pluralization.
sub maybe-plural (Int:D $count, Str:D $noun) is export {
    return $count > 1 ?? $noun ~ 's' !! $noun;
}
