use v6;
use Test;
use Subcommander;

my class App does Subcommander::Application {
    # is option implies is rw
    has $.attr is option;
    has $!hidden;

    method hidden { $!hidden }

    method rw-method is option {
        return-rw $!hidden
    }

    method cmd() is subcommand {
    }
}

plan *;

my $app;

$app = App.new;
$app.run(['cmd']);
ok !$app.attr.defined;
ok !$app.hidden.defined;

$app = App.new;
$app.run(['--attr', 'foo', 'cmd']);

is $app.attr, 'foo';
ok !$app.hidden.defined;

done();

# XXX mix with command options in the run invocation
# XXX try is ro is option
# XXX try conflicting with command options
# XXX boolean options
# XXX type coercion (Int, type map stuff)
# XXX aliases? (methods that assign to the same attr)
# XXX slurpy options?
# XXX list options
# XXX unknown options
