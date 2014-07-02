use v6;
use Test;
use App::Subcommander;

my $prev-name1;
my $prev-name2;
my $prev-name;
my $prev-age;
my $prev-male;

my class App does App::Subcommander {
    method cmd(Str $name1, Str $name2, Str :$name, Int :$age, Bool :$male = False) is subcommand {
        $prev-name1 = $name1;
        $prev-name2 = $name2;
        $prev-name  = $name;
        $prev-age   = $age;
        $prev-male  = $male;
    }
}

plan 5;

App.new.run(['cmd', '--name=Bob', 'Fred', '--age=10', 'Terry', '--male']);

is $prev-name1, 'Fred';
is $prev-name2, 'Terry';
is $prev-name, 'Bob';
is $prev-age, 10;
is $prev-male, True;
