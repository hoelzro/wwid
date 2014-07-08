use v6;
use Test;
use App::Subcommander;

my $prev-arg;
my @prev-names;
my @prev-values;

sub reset {
    $prev-arg   = Str;
    @prev-names = ();
}

my class App does Subcommander::Application {
    method listy(Str $arg, Str :@names) is subcommand {
        $prev-arg   = $arg;
        @prev-names = @names;
    }

    method listy-with-alias(Str $arg, Str :pen-names(:@names)) is subcommand {
        $prev-arg   = $arg;
        @prev-names = @names;
    }

    method int-listy(Str $arg, Int :@values) is subcommand {
        $prev-arg    = $arg;
        @prev-values = @values;
    }
}

plan 6;

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run(['listy', 'test', '--names=Bob', '--names=Fred']);

is $prev-arg, 'test';
is_deeply @prev-names.item, ['Bob', 'Fred'];

reset();

App.new.run(['listy-with-alias', 'test', '--names=Bob', '--pen-names=Fred']);

is $prev-arg, 'test';
is_deeply @prev-names.item, ['Bob', 'Fred'];

reset();

App.new.run(['int-listy', 'test', '--values=10', '--values=20']);

is $prev-arg, 'test';
is_deeply @prev-values.item, [10, 20];
