use v6;

use Test;
use App::Subcommander;

plan 3;

my $exception;

try {
    my class App does App::Subcommander {
        method foo is subcommand('duplicate') {}
        method bar is subcommand('duplicate') {}
    }

    CATCH { default { $exception = $_ } }
}

skip 'NYI', 1;
#ok $exception.defined, 'Trying to define duplicate command names should fail';

$exception = Any;

try {
    my class App does App::Subcommander {
        method foo(Str @options) is subcommand {}
    }

    CATCH { default { $exception = $_ } }
}

skip 'NYI', 1;
#ok $exception.defined, 'Trying to define a command with a Positional positional paramater should fail';

$exception = Any;

try {
    my class App does App::Subcommander {
        method foo(Str %options) is subcommand {}
    }

    CATCH { default { $exception = $_ } }
}

skip 'NYI', 1;
#ok $exception.defined, 'Trying to define a command with an Associative positional paramater should fail';
