use v6;
use lib 'lib', 't/lib';

use Test::Predicates;

ok( True, 'test 1' );
bail('things are going wrong');
ok(True);
done-testing();
