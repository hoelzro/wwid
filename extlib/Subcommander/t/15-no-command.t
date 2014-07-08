use v6;
use Test;
use Subcommander;

my $show-help-called;

my class App does Subcommander::Application {
    method show-help {
        $show-help-called = True;
    }
}

plan 1;

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run([]);

ok $show-help-called, 'show-help should be called if no command is provided';
