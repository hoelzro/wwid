use v6;
use Test;
use App::Subcommander;

plan 7;

my Str $prev-name;
my Bool $prev-flag;

sub reset {
    $prev-name = Str;
    $prev-flag = Bool;
}

my class App is App::Subcommander {
    method has-aliases(Str :pseudonym(:$name)) is subcommand {
        $prev-name = $name;
    }

    method has-required-aliases(Str :pseudonym(:$name)!) is subcommand {
        $prev-name = $name;
    }

    method has-bool-aliases(Bool :fahne(:$flag)) is subcommand {
        $prev-flag = $flag;
    }
}

App.new.run(['has-aliases', '--name=Steve']);

is $prev-name, 'Steve', 'sanity check';

reset();

App.new.run(['has-aliases', '--pseudonym=Mark']);

is $prev-name, 'Mark', 'Named parameters with more than one name should be registered as valid options';

reset();

App.new.run(['has-required-aliases', '--name=Steve']);

is $prev-name, 'Steve', 'sanity check';

reset();

App.new.run(['has-required-aliases', '--pseudonym=Mark']);

is $prev-name, 'Mark', 'Named parameters with more than one name should be registered as valid options';

reset();

App.new.run(['has-aliases', '--pseudonym=Mark', '--name=Terry']);

is $prev-name, 'Terry', 'Aliases and original names should overwrite each other';

reset();

App.new.run(['has-bool-aliases', '--nofahne']);

is $prev-flag, False, 'Boolean flag negation should work with aliases';

reset();

App.new.run(['has-bool-aliases', '--no-fahne']);

is $prev-flag, False, 'Boolean flag negation should work with aliases';

reset();
