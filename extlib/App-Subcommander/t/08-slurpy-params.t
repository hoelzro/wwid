use v6;
use Test;
use App::Subcommander;

my $prev-name;
my @prev-rest;
my %prev-rest;

sub reset {
    $prev-name = Str;
    @prev-rest = ();
    %prev-rest = ();
}

my class App does Subcommander::Application {
    method slurpy-named(Str $name, *%rest) is subcommand {
        $prev-name = $name;
        %prev-rest = %rest;
    }

    #`« typed slurpies aren't supported yet =(
    method slurpy-pos(Str $name, Str *@rest) is subcommand {
        $prev-name = $name;
        @prev-rest = @rest;
    }

    method slurpy-both(Str $name, Str *@rest, *%rest) is subcommand {
        $prev-name = $name;
        @prev-rest = @rest;
        %prev-rest = %rest;
    }

    method slurpy-int(Str $name, Int *@rest) is subcommand {
        $prev-name = $name;
        @prev-rest = @rest;
    }
    »

    # until they *are* supported
    method slurpy-pos(Str $name, *@rest) is subcommand {
        $prev-name = $name;
        @prev-rest = @rest;
    }

    method slurpy-both(Str $name, *@rest, *%rest) is subcommand {
        $prev-name = $name;
        @prev-rest = @rest;
        %prev-rest = %rest;
    }
}

plan *;

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run(['slurpy-pos', 'Bob', 'goes', 'to', 'the', 'store']);

is $prev-name, 'Bob';
is_deeply @prev-rest.item, ['goes', 'to', 'the', 'store'];

reset();

App.new.run(['slurpy-named', 'Bob', '--age=10', '--location=Home']);

is $prev-name, 'Bob';
is_deeply %prev-rest.item, { :age<10>, :location<Home> };

reset();

App.new.run(['slurpy-both', 'Darmok', 'and', 'Jalad', '--season=5', '--episode=2']);

is $prev-name, 'Darmok';
is_deeply @prev-rest.item, ['and', 'Jalad'];
is_deeply %prev-rest.item, { :season<5>, :episode<2> };

reset();

skip "typed slurpies aren't supported", 4;
#App.new.run(['slurpy-int', 'Joe', 1, 2, 3]);

#is $prev-name, 'Joe';
#ok @prev-rest[0] eqv 1;
#ok @prev-rest[1] eqv 2;
#ok @prev-rest[2] eqv 3;

reset();

done();
