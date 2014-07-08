use v6;

use Test;
use App::Subcommander;

plan 3;

my $*ERR = open(IO::Spec.devnull, :w);

my $exception;

try {
    my class App does Subcommander::Application {
        method foo is subcommand('duplicate') {}
        method bar is subcommand('duplicate') {}
    }

    App.new.run(['duplicate']);

    CATCH { default { $exception = $_ } }
}

ok $exception.defined, 'Trying to define duplicate command names should fail';

$exception = Any;

try {
    my class App does Subcommander::Application {
        method foo(Str @options) is subcommand {}
    }

    App.new.run(['foo']);

    CATCH { default { $exception = $_ } }
}

ok $exception.defined, 'Trying to define a command with a Positional positional paramater should fail';

try {
}

$exception = Any;

try {
    my class App does Subcommander::Application {
        method foo(Str %options) is subcommand {}
    }

    App.new.run(['foo']);

    CATCH { default { $exception = $_ } }
}

ok $exception.defined, 'Trying to define a command with an Associative positional paramater should fail';
