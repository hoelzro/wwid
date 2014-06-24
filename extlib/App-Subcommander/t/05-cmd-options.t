use v6;

use Test;
use App::Subcommander;

my $prev-name;
my $show-help-called;

sub reset {
    $prev-name = Str;
    $show-help-called = False;
}

my class App does App::Subcommander {
    method do-stuff(Str :$name = 'Bob') is subcommand {
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

is $prev-name, 'Fred', 'double dash followed by equals';
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
