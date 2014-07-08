use v6;
use Test;
use Subcommander;

my class Color {
    has $.r = 0;
    has $.g = 0;
    has $.b = 0;
}

multi sub infix:<eqv>(Color $a, Color $b) returns Bool {
    ?all(
        $a.r == $b.r,
        $a.g == $b.g,
        $a.b == $b.b
    )
}

my class ColorParseException is Exception {
    method message {
        'Failed to parse color'
    }
}

my class MyTypeResolver does Subcommander::TypeResolver {
    multi method coerce(Str $from, Color $to) {
        given $from {
            when 'red' {
                Color.new(:r(255))
            }

            when 'green' {
                Color.new(:g(255))
            }

            when 'blue' {
                Color.new(:b(255))
            }

            when m:sigspace/^'rgb(' [(\d+) ** 3 % ','] ')'$/ {
                Color.new(
                    :r(+$/[0][0]), # simpler?
                    :g(+$/[0][1]),
                    :b(+$/[0][2]),
                )
            }

            default {
                ColorParseException.new.throw;
            }
        }
    }
}

my $previous-color;

sub reset {
    $previous-color = Any;
}

my class App does Subcommander::Application {
    method type-resolver(*@args, *%kwargs) { MyTypeResolver.new(|@args, |%kwargs) }

    method custom-type-pos(Color $color) is subcommand {
        $previous-color = $color;
    }

    method custom-type-named(Color :$color) is subcommand {
        $previous-color = $color;
    }
}

plan *;

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run(['custom-type-pos', 'red']);

ok $previous-color eqv Color.new(:r(255));

reset();

App.new.run(['custom-type-named', '--color=green']);

ok $previous-color eqv Color.new(:g(255));

reset();

done();

# XXX subtype
# XXX enum
