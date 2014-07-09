use v6;
use Test;
use Subcommander;

my class App does Subcommander::Application {
    has $.attr is option;
    has $!hidden;

    has $.prev-opt is rw;

    method hidden { $!hidden }

    method rw-method is option {
        return-rw $!hidden
    }

    method cmd(Str :$opt) is subcommand {
        $.prev-opt = $opt;
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
ok !$app.prev-opt.defined;

$app = App.new;
$app.run(['--attr', 'foo', '--rw-method', 'bar', 'cmd']);

is $app.attr, 'foo';
is $app.hidden, 'bar';
ok !$app.prev-opt.defined;

$app = App.new;
$app.run(['--rw-method', 'bar', 'cmd', '--opt', 'value']);

ok !$app.attr.defined;
is $app.hidden, 'bar';
is $app.prev-opt, 'value';

done();

# XXX try conflicting with command options
# XXX boolean options
# XXX type coercion (Int, type map stuff)
# XXX aliases? (methods that assign to the same attr)
# XXX slurpy options?
# XXX list options
# XXX unknown options
# XXX is option('hello')
