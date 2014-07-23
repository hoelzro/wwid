use v6;
use Subcommander;

my class Effort {
}

class WWID::CLI does Subcommander::Application {
    #| Creates a new task
    method new_task(Str :$name!, Effort :$effort!) is subcommand('new') {
    }

    #| Asks wwid for something new to work on
    method next_task() is subcommand('next') {
        say '*** STUB next task ***';
    }

    #| Mark a task as completed
    method complete(Str :$name!) is subcommand {
    }

    #| Recalculates the value for tasks that need it
    method recalcuate() is subcommand {
    }
}
