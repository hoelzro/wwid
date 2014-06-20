my role Subcommand {
    has Str $.command-name is rw;
}

our role App::Subcommander {
    method !parse-command-line(@args) {
        ( @args[0], {} )
    }

    method !get-commands {
        gather {
            for self.^methods -> $method {
                if +$method.candidates > 1 && any($method.candidates.map({ $_ ~~ Subcommand })) {
                    die "multis not yet supported by App::Subcommander";
                }
                take $method.command-name => $method if $method ~~ Subcommand;
            }
        }
    }

    method run(@args) returns int {
        my ( $command, %options ) = self!parse-command-line(@args);
        my %all-commands = self!get-commands;

        unless $command.defined && (%all-commands{$command}:exists) {
            self.show-help;
            return 1;
        }

        my $f = %all-commands{$command};

        if +$f.candidates > 1 {
            die 'multis not yet supported by App::Subcommander';
        }

        $f(self, |%options);

        return 0;
    }

    method show-help {
        $*ERR.say: 'showing help!';
    }
}

multi trait_mod:<is>(Routine $r, :subcommand($name)! is copy) is export {
    if $name ~~ Bool {
        $name = $r.name;
    }
    $r does Subcommand;
    $r.command-name = $name;
}
