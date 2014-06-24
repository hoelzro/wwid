use v6;

use Test;
use App::Subcommander;

my $prev-name;
my $prev-required-name;
my $show-help-called;

sub reset {
    $prev-name = Str;
    $prev-required-name = Str;
    $show-help-called = False;
}

my class App does App::Subcommander {
    method do-stuff(Str :$name = 'Bob') is subcommand {
        $prev-name = $name;
    }

    method has-required-flag(Str :$name!) is subcommand {
        $prev-required-name = $name;
    }

    method show-help {
        $show-help-called = True;
    }
}

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run(['do-stuff']);

is $prev-name, 'Bob', 'the default value should be used if no value is provided';
ok !$show-help-called, 'show-help should not have been called even if a value for an option is not provided';

reset();

App.new.run(['do-stuff', '--name=Fred']);

is $prev-name, 'Fred', 'the value used should follow the equals sign';
ok !$show-help-called, 'show-help should not have been called if a value for an option has been provided';

reset();

App.new.run(['do-stuff', '--name', 'Fred']);

is $prev-name, 'Fred', 'the value used may also be the following parameter';
ok !$show-help-called, 'show-help should not have been called if a value for an option has been provided';

reset();

App.new.run(['do-stuff', '--name']);

ok !$prev-name.defined, 'the subcommand should not be called if no value is provided for an option';
ok $show-help-called, 'show-help should be called if no value is provided for an option';

reset();

App.new.run(['has-required-flag']);

ok !$prev-required-name.defined, 'missing required named parameter should not call the subcommand';
ok $show-help-called, 'show-help should be called if required named parameter is missing';

reset();

App.new.run(['has-required-flag', '--name=Fred']);

is $prev-required-name, 'Fred', 'passing in a value to a required option should work';
ok !$show-help-called, 'show-help should not be called if required option is given a value';

reset();

done();

# XXX boolean option
# XXX integer option
# XXX "mandatory" option
