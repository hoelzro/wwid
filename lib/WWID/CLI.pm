use v6;
use Subcommander;

my class Effort {
}

class WWID::CLI does Subcommander::Application {
    #| Creates a new task
    method new_task(
        Str :$name!,     #= The name for the task
        Effort :$effort! #= The estimated amount of effort it will take
    ) is subcommand('new') {
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

    #| Imports a CSV of existing tasks
    method import() is subcommand {
    }
}
