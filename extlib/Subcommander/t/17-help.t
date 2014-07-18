use v6;
use Test;
use Subcommander;

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

# non-existing command
# non-existing option
# bad parse for option
# no command provided
# --help
