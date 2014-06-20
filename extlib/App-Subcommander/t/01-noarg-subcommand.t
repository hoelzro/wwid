use v6;

use Test;
use App::Subcommander;

plan 12;

my Bool $called-foo    = False;
my Bool $called-bar    = False;
my Bool $called-no_cmd = False;

sub reset {
    $called-foo = $called-bar = $called-no_cmd = False;
}

my class App does App::Subcommander {
    method foo is subcommand {
        $called-foo = True;
    }

    method bar is subcommand('baz') {
        $called-bar = True;
    }

    method no_cmd {
    }
}

my $*ERR = open(IO::Spec.devnull, :w);

App.new.run(['foo']);

ok($called-foo, 'foo should have been called via run["foo"]');
ok(!$called-bar, 'bar should not have been called via run["foo"]');
ok(!$called-no_cmd, 'no_cmd should not have been called via run["foo"]');

reset();

App.new.run(['baz']);

ok(!$called-foo, 'foo should not have been called via run["baz"]');
ok($called-bar, 'bar should have been called via run["baz"]');
ok(!$called-no_cmd, 'no_cmd should not have been called via run["baz"]');

reset();

App.new.run(['bar']);

ok(!$called-foo, 'foo should not have been called via run["bar"]');
ok(!$called-bar, 'bar should not have been called via run["bar"]');
ok(!$called-no_cmd, 'no_cmd should not have been called via run["bar"]');

reset();

App.new.run(['no_cmd']);

ok(!$called-foo, 'foo should not have been called via run["no_cmd"]');
ok(!$called-bar, 'bar should not have been called via run["no_cmd"]');
ok(!$called-no_cmd, 'no_cmd should not have been called via run["no_cmd"]');
