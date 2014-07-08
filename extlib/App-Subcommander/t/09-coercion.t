use v6;
use Test;
use Subcommander;

my $prev-value;

sub reset {
    $prev-value = Int;
}

my class App does Subcommander::Application {
    method coercing(Str $value as Int) is subcommand {
        $prev-value = $value;
    }
}

plan 1;

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run(['coercing', '10']);

ok $prev-value eqv 10, 'type coercion should be unaffected';
