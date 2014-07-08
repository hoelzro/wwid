use v6;
use Test;
use Subcommander;

my class App does Subcommander::Application {
    method ok is subcommand {}
}

my $*ERR = open(IO::Spec.devnull, :w);

plan 2;

is App.new.run(['ok']), 0, 'A successful run should return 0';
isnt App.new.run(['not-ok']), 0, 'A failed run should not return 0';
