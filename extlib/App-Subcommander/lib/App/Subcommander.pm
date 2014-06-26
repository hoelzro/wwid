my role Subcommand {
    has Str $.command-name is rw;
}

my class SubcommanderException is Exception {
    has Str $.message;

    method new(Str $message) {
        self.bless(:$message);
    }
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
                SubcommanderException.new("Option '$key' is a flag, and thus doesn't take a value").throw;
            } else {
                $value = 'True'; # coercion from Str → Bool will happen later on
            }
        }

        ( $key, $value )
    }

    method !is-option-terminator($arg) {
        $arg eq '--'
    }

    method !fix-type($expected-type, $value is copy) {
        my $name = $expected-type.^name;

        if $value !~~ $expected-type {
            # $value = try $value."$name'(); didn't work, look into this
            try {
                $value = $value."$name"();
                CATCH {
                    default {
                        SubcommanderException.new("Failed to convert '$value'").throw;
                    }
                }
            }
        }
        $value
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
                    my $name;
                    ( $name, @command-args ) = @copy;
                    $subcommand = self!get-commands(){$name};
                    if $subcommand !~~ Subcommand {
                        SubcommanderException.new("No such command '$name'").throw;
                    }
                    ( $pos-type-info, $named-type-info ) = self!determine-type-info($subcommand);
                }
                return
            } elsif self!is-option($arg) {
                my ( $name, $value ) = self!parse-option($named-type-info, $arg);

                unless $value.defined {
                    unless @copy {
                        SubcommanderException.new("Option '$name' requires a value").throw;
                    }
                    $value = @copy.shift;
                }
                if $named-type-info{$name} ~~ Positional { # XXX is ~~ the right test?
                    unless %command-options{$name}:exists {
                        %command-options{$name} = [];
                    }
                    %command-options{$name}.push: self!fix-type($named-type-info{$name}.of, $value);
                } else {
                    %command-options{$name} = self!fix-type($named-type-info{$name}, $value);
                }
            } else {
                if $subcommand.defined {
                    @command-args.push: self!fix-type($pos-type-info[ +@command-args ], $arg);
                } else {
                    $subcommand = self!get-commands(){$arg};
                    if $subcommand !~~ Subcommand {
                        SubcommanderException.new("No such command '$arg'").throw;
                    }
                    ( $pos-type-info, $named-type-info ) = self!determine-type-info($subcommand);
                }
            }
        }
        return ( $subcommand, @command-args.item, %command-options.item );
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

        if +$pos-args < $arity {
            SubcommanderException.new('Too few arguments').throw;
        }
        if +$pos-args > $count {
            SubcommanderException.new('Too many arguments').throw;
        }
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
                my $name = $param.named_names[0];
                SubcommanderException.new("Required option '$name' not provided").throw;
            }
        }
        if %unaccounted-for && !$saw-slurpy-named {
            my $first = %unaccounted-for.keys.sort[0];
            SubcommanderException.new("Unrecognized option '$first'").throw;
        }
    }

    method run(@args) returns int {
        try {
            my ( $command, $args, $cmd-options ) = self!parse-command-line(@args);

            if +$command.candidates > 1 {
                die 'multis not yet supported by App::Subcommander';
            }

            self!check-args($command, $args, $cmd-options);

            $command(self, |@($args), |%($cmd-options));

            return 0;

            CATCH {
                when SubcommanderException {
                    $*ERR.say: $_.message;
                    self.show-help;
                    return 1;
                }
            }
        }
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
