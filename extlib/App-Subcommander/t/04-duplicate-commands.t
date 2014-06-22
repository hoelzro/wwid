use v6;

use Test;
use App::Subcommander;

plan 1;

my $exception;

try {
    my class App does App::Subcommander {
        method foo is subcommand('duplicate') {}
        method bar is subcommand('duplicate') {}
    }

    CATCH { default { $exception = $_ } }
}

say App::Subcommander.HOW;
ok $exception.defined, 'Trying to define duplicate command names should fail';
