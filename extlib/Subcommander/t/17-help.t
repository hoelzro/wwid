use v6;
use Test;
use Subcommander;
use IO::String;

sub collect-help($app, &action) {
    my $*ERR = IO::String.new;

    &action($app);

    return ~$*ERR;
}

# XXX class comment?
my class App does Subcommander::Application {
    #| Does good things.  They may come to you if you wait!
    #| Batteries not included.
    method good-cmd(
        #| The thing to do good things to
        Str $target,
        #| Something optional
        Str :$option1,
        #| Something else optional
        Int :$option2
    ) is subcommand
    {
    }
}

my $*PROGRAM_NAME = 'App';

my $TOP_LEVEL_HELP = qq:to/END_HELP/;
Usage: App [command]

good-cmd	Does good things.
END_HELP

my $help;

$help = collect-help(App.new, {
    $^app.run([]);
});

is $help, $TOP_LEVEL_HELP;

#$help = collect-help(App.new, {
    #$^app.run(['--help']);
#});

#is $help, $TOP_LEVEL_HELP;

# non-existing command
# non-existing option
# bad parse for option
# no command provided
# --help, -h
# --help vs --help-commands?
# help command
# -?
# --version, -v
# version command
