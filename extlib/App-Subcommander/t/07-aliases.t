use v6;
use Test;
use App::Subcommander;

plan 5;

my Str $prev-name;

sub reset {
    $prev-name = Str;
}

my class App is App::Subcommander {
    method has-aliases(Str :pseudonym(:$name)) is subcommand {
        $prev-name = $name;
    }

    method has-required-aliases(Str :pseudonym(:$name)!) is subcommand {
        $prev-name = $name;
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
