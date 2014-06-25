use v6;

use Test;
use App::Subcommander;

my $prev-name;
my $prev-value;
my $prev-flag;
my $prev-arg;
my $prev-required-name;
my $show-help-called;

sub reset {
    $prev-name = Str;
    $prev-value = Int;
    $prev-flag = Bool;
    $prev-arg = Str;
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

    method go-int(Int :$value) is subcommand {
        $prev-value = $value;
    }

    method go-bool(Str $arg?, Bool :$flag) is subcommand {
        $prev-flag = $flag;
        $prev-arg = $arg;
    }

    method go-any(:$any) is subcommand {
        ok $any.WHAT eqv Str, 'A looser type constraint than Str should still be passed strings';
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

App.new.run(['do-stuff', '--bad-name=Fred']);

ok !$prev-name.defined, 'passing in an unrecognized option should not invoke the subcommand';
ok $show-help-called, 'show-help should be called if an unrecognized option is passed in';

reset();

App.new.run(['go-int', '--value=10']);

ok $prev-value eqv 10, 'The value should have been properly converted between types';
ok !$show-help-called, 'show-help should not be called in case of success';

reset();

App.new.run(['go-int', '--value=foo']);

ok !$prev-value.defined, 'The subcommand should not be called if a type conversion failed';
ok $show-help-called, 'show-help should be called if a type conversion failed';

reset();

App.new.run(['go-bool', '--flag']);

is $prev-flag, True, 'Passing just --flag should work for boolean options';
ok !$prev-arg.defined, 'No extra arguments should go through';
ok !$show-help-called, 'show-help should not be called in case of success';

reset();

App.new.run(['go-bool', '--flag', 'value']);

is $prev-flag, True, 'Passing --flag should work for boolean options';
is $prev-arg, 'value', 'Extra arguments should go through the positional args';
ok !$show-help-called, 'show-help should not be called in case of success';

reset();

App.new.run(['go-bool', '--flag=value']);

ok !$prev-flag.defined, 'Passing boolean --flag with an explicit value should fail ';
ok $show-help-called, 'show-help should not be called in case of success';

reset();

App.new.run(['go-any', '--any=value']);

reset();

done();
