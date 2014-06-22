use v6;

use Test;
use App::Subcommander;

my Bool $needs3-called       = False;
my Bool $has-optional-called = False;
my Bool $show-help-called    = False;

sub reset {
    $needs3-called       = False;
    $has-optional-called = False;
    $show-help-called    = False;
}

my class App does App::Subcommander {
    method needs3(Str $one, Str $two, Str $three) is subcommand {
        $needs3-called = True;
    }

    method has-optional(Str $one?, Str $two?, Str $three?) is subcommand {
        $has-optional-called = True;
    }

    method show-help {
        $show-help-called = True;
    }
}

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run(['needs3', 'one', 'two', 'three']);

ok $needs3-called, 'needs3 should have been called via run(["needs3", ...])';
ok !$has-optional-called, 'has-optional should not have been called via run(["needs3", ...])';
ok !$show-help-called, 'show-help should not have been called when needs3 is given enough arguments';

reset();

App.new.run(['has-optional']);

ok !$needs3-called, 'needs3 should not have been called via run(["has-optional"])';
ok $has-optional-called, 'has-optional should have been called via run(["has-optional"])';
ok !$show-help-called, 'show-help should not have been called when has-optional is given enough arguments';

done();

# XXX shows help when you don't have enough
# XXX shows help when you have too many
# XXX make sure integer-like arguments stay as Strs
# XXX make sure optional processing works
# XXX make sure exceptions propagate
