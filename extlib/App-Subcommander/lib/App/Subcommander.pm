my role Subcommand {
    has Str $.command-name is rw;
}

our role App::Subcommander {
    method !parse-command-line(@args) {
        ( @args[0], {} )
    }

    method !get-commands {
        self.^methods.grep({ $_ ~~ Subcommand }).map({ .command-name => $_ })
    }

    method run(@args) returns int {
        my ( $command, %options ) = self!parse-command-line(@args);
        my %all-commands = self!get-commands;

        unless $command.defined && (%all-commands{$command}:exists) {
            self.show-help;
            return 1;
        }

        %all-commands{$command}(self, |%options);

        return 0;
    }

    method show-help {
        say 'showing help!';
    }
}

multi trait_mod:<is>(Routine $r, :subcommand($name)! is copy) is export {
    if $name ~~ Bool {
        $name = $r.name;
    }
    $r does Subcommand;
    $r.command-name = $name;
}
