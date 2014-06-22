use v6;

use Test;
use App::Subcommander;

my Bool $needs3-called       = False;
my Bool $has-optional-called = False;
my Bool $show-help-called    = False;
my @previous-needs3-args;
my @previous-has-optional-args;

sub reset {
    $needs3-called       = False;
    $has-optional-called = False;
    $show-help-called    = False;

    @previous-needs3-args       = ();
    @previous-has-optional-args = ();
}

my class App does App::Subcommander {
    method needs3(Str $one, Str $two, Str $three) is subcommand {
        @previous-needs3-args = ( $one, $two, $three );
        $needs3-called = True;
    }

    method has-optional(Str $one?, Str $two?, Str $three?) is subcommand {
        @previous-has-optional-args = ( $one, $two, $three );
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
is_deeply(@previous-needs3-args.item, ['one', 'two', 'three']);

reset();

App.new.run(['has-optional']);

ok !$needs3-called, 'needs3 should not have been called via run(["has-optional"])';
ok $has-optional-called, 'has-optional should have been called via run(["has-optional"])';
ok !$show-help-called, 'show-help should not have been called when has-optional is given enough arguments';
is_deeply(@previous-has-optional-args.item, [Str, Str, Str]);

reset();

App.new.run(['needs3', 'one', 'two']);

ok !$needs3-called, 'needs3 should not have been called via run(["needs3", ...2 args...])';
ok !$has-optional-called, 'has-optional should not have been called via run(["needs3", ...2 args...])';
ok $show-help-called, 'show-help should have been called when needs3 is not given enough arguments';

reset();

App.new.run(['needs3', 'one', 'two', 'three', 'four']);

ok !$needs3-called, 'needs3 should not have been called via run(["needs3", ...4 args...])';
ok !$has-optional-called, 'has-optional should not have been called via run(["needs3", ...4 args...])';
ok $show-help-called, 'show-help should have been called when needs3 is given too many arguments';

reset();

App.new.run(['has-optional', 'one']);

ok !$needs3-called, 'needs3 should not have been called via run(["has-optional", ...1 arg...])';
ok $has-optional-called, 'has-optional should have been called via run(["has-optional", ...1 arg...])';
ok !$show-help-called, 'show-help should not have been called when has-optional is given enough arguments';
is_deeply(@previous-has-optional-args.item, ['one', Str, Str]);

done();
