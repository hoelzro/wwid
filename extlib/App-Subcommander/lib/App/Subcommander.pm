my role Subcommand {
    has Str $.command-name is rw;
}

our role App::Subcommander {
    method !is-option($arg) {
        $arg ~~ /^ '-'/
    }

    method !parse-option($arg) {
        if $arg ~~ /^ '--' $<key>=(<-[=]>+) '=' $<value>=(.*) $/ {
            ( ~$<key>, ~$<value> )
        } else {
            ( $arg.substr(2), Str )
        }
    }

    method !is-option-terminator($arg) {
        $arg eq '--'
    }

    method !parse-command-line(@args) { # should be 'is copy', but I get an odd error
        my %command-options;
        my %app-options;
        my @command-args;
        my $subcommand;
        my @copy = @args;

        while @copy {
            my $arg = @copy.shift;

            if self!is-option-terminator($arg) {
                if $subcommand.defined {
                    @command-args.push: @copy;
                } else {
                    ( $subcommand, @command-args ) = @copy;
                    $subcommand = self!get-commands(){$subcommand};
                    if $subcommand !~~ Subcommand {
                        return;
                    }
                }
                return
            } elsif self!is-option($arg) {
                my ( $name, $value ) = self!parse-option($arg);
                unless $value.defined {
                    return unless @copy;
                    $value = @copy.shift;
                }
                %command-options{$name} = $value; # XXX types
            } else {
                if $subcommand.defined {
                    @command-args.push: $arg;
                } else {
                    $subcommand = $arg;
                    $subcommand = self!get-commands(){$subcommand};
                    if $subcommand !~~ Subcommand {
                        return;
                    }
                }
            }
        }
        return ( $subcommand, @command-args.item, %app-options.item, %command-options.item );
    }

    method !get-commands {
        my %result = gather {
            for self.^methods -> $method {
                if +$method.candidates > 1 && any($method.candidates.map({ $_ ~~ Subcommand })) {
                    die "multis not yet supported by App::Subcommander";
                }
                take $method.command-name => $method if $method ~~ Subcommand;
            }
        };
        return %result.item;
    }

    method !check-args($command, $pos-args, $named-args) {
        my $signature = $command.signature;

        my $arity = $signature.arity - 1; # 1 is for the invocant
        my $count = $signature.count - 1;
        my %unaccounted-for = %($named-args);

        return False unless $arity <= +$pos-args <= $count;
        for $signature.params -> $param {
            next if $param.invocant;
            next unless $param.named;
            next if $param.slurpy;

            my $name = $param.named_names[0];
            %unaccounted-for{$name}:delete;
            if !$param.optional && !($named-args{$name}:exists) {
                return False;
            }
        }
        if %unaccounted-for {
            return False;
        }
        return True;
    }

    method run(@args) returns int {
        my ( $command, $args, $app-options, $cmd-options ) = self!parse-command-line(@args);

        unless $command.defined {
            self.show-help;
            return 1;
        }

        if +$command.candidates > 1 {
            die 'multis not yet supported by App::Subcommander';
        }

        unless self!check-args($command, $args, $cmd-options) {
            self.show-help;
            return 1;
        }

        $command(self, |@($args), |%($cmd-options));

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
