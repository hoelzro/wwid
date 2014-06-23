use v6;

use Test;
use App::Subcommand;

my $prev-name;
my $show-help-called;

sub reset {
    $prev-name = Str;
    $show-help-called = False;
}

my class App does App::Subcommand {
    method do-stuff(Str :$name = 'Bob') {
        $prev-name = $name;
    }

    method show-help {
        $show-help-called = True;
    }
}

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run(['do-stuff']);

is $prev-name, 'Bob';
ok !$show-help-called;

reset();

App.new.run(['do-stuff', '--name=Fred']);

is $prev-name, 'Fred';
ok !$show-help-called;

reset();

App.new.run(['do-stuff', '--name', 'Fred']);

is $prev-name, 'Fred';
ok !$show-help-called;

reset();

App.new.run(['do-stuff', '--name', 'Fred']);

is $prev-name, 'Fred';
ok !$show-help-called;

reset();

App.new.run(['do-stuff', '--name']);

ok !$prev-name.defined;
ok $show-help-called;

reset();

done();

# XXX boolean option
# XXX integer option
# XXX "mandatory" option
