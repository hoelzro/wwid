my role Subcommand {
    has Str $.command-name is rw;
}

our role App::Subcommander {
    method !is-option($arg) {
        $arg ~~ /^ '-'/
    }

    method !parse-option($type-info, $arg) {
        my ( $key, $value ) =
            do if $arg ~~ /^ '--' $<key>=(<-[=]>+) '=' $<value>=(.*) $/ {
                ( ~$<key>, ~$<value> )
            } else {
                ( $arg.substr(2), Str )
            };

        if $type-info{$key} eqv Bool {
            if $value.defined {
                return; # this isn't allowed
            } else {
                $value = 'True'; # coercion from Str → Bool will happen later on
            }
        }

        ( $key, $value )
    }

    method !is-option-terminator($arg) {
        $arg eq '--'
    }

    method !fix-type($expected-type, $value) {
        # if we don't have an expected type, just return the value; we'll
        # deal with it later
        my $name = $expected-type.^name;
        return $value if $value ~~ $expected-type; # just return it if the type is right
        return $expected-type eqv Any ?? $value !! try $value."$name"();
    }

    method !determine-type-info($command) {
        my @positional;
        my %named;

        for $command.signature.params -> $param {
            next if $param.invocant;
            next if $param.slurpy;

            if $param.named {
                for $param.named_names -> $name {
                    %named{$name} = $param.type;
                }
            } else {
                @positional.push: $param.type;
            }
        }

        ( @positional.item, %named.item )
    }

    method !parse-command-line(@args) { # should be 'is copy', but I get an odd error
        my %command-options;
        my %app-options;
        my @command-args;
        my $subcommand;
        my @copy = @args;

        my $pos-type-info;
        my $named-type-info;

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
                    ( $pos-type-info, $named-type-info ) = self!determine-type-info($subcommand);
                }
                return
            } elsif self!is-option($arg) {
                my ( $name, $value ) = self!parse-option($named-type-info, $arg);
                return unless $name.defined;
                unless $value.defined {
                    return unless @copy;
                    $value = @copy.shift;
                }
                $value = self!fix-type($named-type-info{$name}, $value);
                return unless $value.defined;
                %command-options{$name} = $value;
            } else {
                if $subcommand.defined {
                    $arg = self!fix-type($pos-type-info[ +@command-args ], $arg);
                    return unless $arg;
                    @command-args.push: $arg;
                } else {
                    $subcommand = $arg;
                    $subcommand = self!get-commands(){$subcommand};
                    if $subcommand !~~ Subcommand {
                        return;
                    }
                    ( $pos-type-info, $named-type-info ) = self!determine-type-info($subcommand);
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
        my $saw-slurpy-named;

        return False unless $arity <= +$pos-args <= $count;
        for $signature.params -> $param {
            next if $param.invocant;
            next unless $param.named;

            if $param.slurpy {
                if $param.gist ne '*%_' { # the compiler adds an implicit slurpy parameter to methods
                    $saw-slurpy-named = True;
                }
                next;
            }

            %unaccounted-for{ $param.named_names }:delete;
            if !$param.optional && !($named-args{$param.named_names.any}:exists) {
                return False;
            }
        }
        if %unaccounted-for && !$saw-slurpy-named {
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
