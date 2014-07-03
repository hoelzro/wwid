use v6;
use Test;

plan 4;

# sanity checks to make sure the Perl 6 implementation we're running
# on behaves as we expect.  If it doesn't, it doesn't mean that
# App::Subcommander will break, but I want to know in case there
# are things I can improve upon or if there's potential for future
# issues

my class TestClass {
    method test-method() {
    }
}

is +TestClass.can('test-method')[0].signature.params.grep(*.gist eq '*%_'), 1, 'make sure that methods get an implicit slurpy named parameter called *%_';

my $out-called;

my class Out {
}

my class In {
    method Out {
        $out-called = True;
        Out.new
    }
}

sub coercing(In $arg as Out) {
}

coercing(In.new);

ok $out-called, 'A method of the same name as the target class should be called for coercion'; 

my $ex;
try {
    EVAL('sub typed-rest(Str $name, Int *@typed-rest) {}');
    CATCH { default { $ex = $_ } }
}

ok $ex.defined, 'typed slurpies should be NYI';

#| preceding comments should work
my class Docced {
#= following comments probably don't
}

is ~Docced.WHY, 'preceding comments should work';
