use v6;
use Test;
use Subcommander;

my class App does Subcommander::Application {
    has $.attr is option;
    has $!hidden;
    has Bool $.flag is option = False;
    has Int $.inty is option;

    has $.prev-opt is rw;
    has $.prev-arg is rw;
    has $.showed-help is rw = False;

    method hidden { $!hidden }

    method rw-method is option {
        return-rw $!hidden
    }

    method cmd(Str :$opt) is subcommand {
        $.prev-opt = $opt;
    }

    method argh(Str $arg?) is subcommand {
        $.prev-arg = $arg;
    }

    method show-help {
        $.showed-help = True;
    }
}

plan *;

my $*ERR = open(IO::Spec.devnull, :w);

my $app;

$app = App.new;
$app.run(['cmd']);
ok !$app.showed-help;
ok !$app.attr.defined;
ok !$app.flag;
ok !$app.hidden.defined;
ok !$app.inty.defined;
ok !$app.prev-opt.defined;
ok !$app.prev-arg.defined;

$app = App.new;
$app.run(['--attr', 'foo', 'cmd']);

ok !$app.showed-help;
is $app.attr, 'foo';
ok !$app.hidden.defined;
ok !$app.flag;
ok !$app.inty.defined;
ok !$app.prev-opt.defined;
ok !$app.prev-arg.defined;

$app = App.new;
$app.run(['--attr', 'foo', '--rw-method', 'bar', 'cmd']);

ok !$app.showed-help;
is $app.attr, 'foo';
is $app.hidden, 'bar';
ok !$app.flag;
ok !$app.inty.defined;
ok !$app.prev-opt.defined;
ok !$app.prev-arg.defined;

$app = App.new;
$app.run(['--rw-method', 'bar', 'cmd', '--opt', 'value']);

ok !$app.showed-help;
ok !$app.attr.defined;
is $app.hidden, 'bar';
ok !$app.flag;
ok !$app.inty.defined;
is $app.prev-opt, 'value';
ok !$app.prev-arg.defined;

$app = App.new;
$app.run(['--flag', 'argh', 'arg']);

ok !$app.showed-help;
ok !$app.attr.defined;
ok !$app.hidden.defined;
ok $app.flag;
ok !$app.inty.defined;
ok !$app.prev-opt.defined;
is $app.prev-arg, 'arg';

$app = App.new;
$app.run(['--inty', '10', 'argh', 'arg']);

ok !$app.showed-help;
ok !$app.attr.defined;
ok !$app.hidden.defined;
ok !$app.flag;
ok $app.inty eqv 10;
ok !$app.prev-opt.defined;
is $app.prev-arg, 'arg';

$app = App.new;
$app.run(['--inty', 'foo', 'argh', 'arg']);

ok $app.showed-help;
ok !$app.attr.defined;
ok !$app.hidden.defined;
ok !$app.flag;
ok !$app.inty.defined;
ok !$app.prev-opt.defined;
ok !$app.prev-arg.defined;

done();

# XXX try conflicting with command options
# XXX type coercion (type map stuff)
# XXX aliases? (methods that assign to the same attr)
# XXX slurpy options?
# XXX list options
# XXX unknown options
# XXX is option('hello')
# XXX demonstrate that --flag --inty problem will set --flag
