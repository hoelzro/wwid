use Subcommander;

my class Effort {
}

class WWID::CLI does Subcommander::Application {
    method new_task(Str :$name!, Effort :$effort!) is subcommand('new') {
    }

    method next_task() is subcommand('next') {
        say '*** STUB next task ***';
    }

    method complete(Str :$name!) is subcommand {
    }

    method recalcuate() is subcommand {
    }
}
