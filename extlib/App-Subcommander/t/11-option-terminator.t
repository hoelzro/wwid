use v6;
use Test;
use App::Subcommander;

my $prev-first;
my $prev-second;
my $prev-opt-value;
my $prev-str-flag;
my $prev-bool-flag;
my $show-help-called;

sub reset {
    $prev-first       = Str;
    $prev-second      = Str;
    $show-help-called = False;
    $prev-opt-value   = Str;
    $prev-str-flag    = Str;
    $prev-bool-flag   = Bool;
}

my class App does App::Subcommander {
    method cmd($first, $second) is subcommand {
        $prev-first  = $first;
        $prev-second = $second;
    }

    method double-dash-cmd($first, $second) is subcommand('--cmd') {
        $prev-first  = $first;
        $prev-second = $second;
    }

    method flag-cmd(Str $opt-value?, Str :$str-flag, Bool :$bool-flag) is subcommand {
        $prev-opt-value = $opt-value;
        $prev-str-flag  = $str-flag;
        $prev-bool-flag = $bool-flag;
    }

    method show-help {
        $show-help-called = True;
    }
}

plan *;

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run(['cmd', 'foo', '--', 'bar']); # make sure -- doesn't end up in args

is $prev-first, 'foo';
is $prev-second, 'bar';
ok !$show-help-called;

reset();

App.new.run(['cmd', '--', 'bar', 'foo']); # make sure it works as first argument

is $prev-first, 'bar';
is $prev-second, 'foo';
ok !$show-help-called;

reset();

App.new.run(['cmd', 'bar', 'foo', '--']); # make sure it works as last argument

is $prev-first, 'bar';
is $prev-second, 'foo';
ok !$show-help-called;

reset();

App.new.run(['cmd', 'foo', '--', '--bar']); # make sure it works with -- options

is $prev-first, 'foo';
is $prev-second, '--bar';
ok !$show-help-called;

reset();

App.new.run(['--', 'cmd', 'bar', 'foo']); # make sure it works before the subcommand

is $prev-first, 'bar';
is $prev-second, 'foo';
ok !$show-help-called;

reset();

App.new.run(['--', '--cmd', 'bar', 'foo']); # make sure it allows funky subcommands

is $prev-first, 'bar';
is $prev-second, 'foo';
ok !$show-help-called;

reset();

App.new.run(['flag-cmd', '--str-flag', '--', '--bar']); # make sure it works with options

is $prev-str-flag, '--bar';
ok !$prev-opt-value.defined;
ok !$prev-bool-flag.defined;
ok !$show-help-called;

reset();

App.new.run(['flag-cmd', '--str-flag', '--']); # make sure it calls for help when it runs out

ok !$prev-str-flag.defined;
ok !$prev-opt-value.defined;
ok !$prev-bool-flag.defined;
ok $show-help-called;

reset();

App.new.run(['flag-cmd', '--bool-flag', '--', '--bar']); # make sure it works with options

ok !$prev-str-flag.defined;
is $prev-opt-value, '--bar';
is $prev-bool-flag, True;
ok !$show-help-called;

reset();

done();
