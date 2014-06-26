use v6;
use Test;
use App::Subcommander;

my $prev-arg;
my @prev-names;

sub reset {
    $prev-arg   = Str;
    @prev-names = ();
}

my class App does App::Subcommander {
    method listy(Str $arg, Str :@names) is subcommand {
        $prev-arg   = $arg;
        @prev-names = @names;
    }
}

plan 2;

App.new.run(['listy', 'test', '--names=Bob', '--names=Fred']);

is $prev-arg, 'test';
is_deeply @prev-names.item, ['Bob', 'Fred'];
