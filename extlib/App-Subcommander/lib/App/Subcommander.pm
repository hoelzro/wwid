my role Subcommand {
    has Str $.command-name is rw;
}

my class SubcommanderException is Exception {
    has Str $.message;

    method new(Str $message) {
        self.bless(:$message);
    }
}

my class NoMoreValues is Exception {
    method message { 'No more values' }
}

my class Option {
    has $.content;

    method Str { $.content }
}

my class Target {
    has $.content;

    method Str { $.content }
}

my class TypeResolver {
    has %!named;
    has @!positional;

    submethod BUILD(:&command) {
        for &command.signature.params -> $param {
            next if $param.invocant;
            next if $param.slurpy;

            if $param.named {
                for $param.named_names -> $name {
                    %!named{$name} = $param.type;
                }
            } else {
                @!positional.push: $param.type;
            }
        }
    }

    method is-array(Str $name) returns Bool {
        %!named{$name} ~~ Positional # XXX is ~~ the right test?
    }

    multi method typeof(Int $pos) {
        @!positional[$pos]
    }

    multi method typeof(Str $name is copy) {
        unless %!named{$name}:exists {
            $name .= subst(/^ no '-'? /, '')
        }
        %!named{$name}
    }
}

my class OptionCanonializer {
    has %!canonical-names;

    submethod BUILD(:&command) {
        %!canonical-names = gather {
            for &command.signature.params -> $param {
                next unless $param.named;
                next if $param.slurpy;

                my $first-name = $param.named_names[0];
                for $param.named_names -> $name {
                    take $name => $first-name;
                }
            }
        };
    }

    method canonicalize(Str $name is copy) returns Str {
        unless %!canonical-names{$name}:exists {
            $name .= subst(/^ no '-'? /, '')
        }
        %!canonical-names{$name} // $name
    }
}

my class OptionParser {
    has @!args;
    has Bool $!seen-terminator = False;

    submethod BUILD(:@!args) {}

    method parse {
        gather {
            while @!args {
                my $arg = @!args.shift;

                if $!seen-terminator {
                    take Target.new(:content($arg));
                } else {
                    if self!is-option-terminator($arg) {
                        $!seen-terminator = True;
                        next;
                    } elsif self!is-option($arg) {
                        take Option.new(:content($arg))
                    } else {
                        take Target.new(:content($arg))
                    }
                }
            }
        }
    }

    method !is-option($arg) {
        $arg ~~ /^ '-'/ && !self!is-option-terminator($arg)
    }

    method !is-option-terminator($arg) returns Bool {
        $arg eq '--'
    }

    method parse-option(TypeResolver $type-resolver, Str $arg) {
        my ( $key, $value ) =
            do if $arg ~~ /^ '--' $<key>=(<-[=]>+) '=' $<value>=(.*) $/ {
                ( ~$<key>, ~$<value> )
            } else {
                ( $arg.substr(2), Str )
            };

        if $type-resolver.typeof($key) eqv Bool {
            if $value.defined {
                SubcommanderException.new("Option '$key' is a flag, and thus doesn't take a value").throw;
            } else {
                $value = 'True'; # coercion from Str → Bool will happen later on
            }
        }

        ( $key, $value )
    }

    method demand-value returns Str {
        unless @!args {
            NoMoreValues.new.throw
        }

        my $value = @!args.shift;

        if $!seen-terminator {
            $value
        } else {
            if self!is-option-terminator($value) {
                $!seen-terminator = True;
                self.demand-value
            } elsif self!is-option($value) {
                NoMoreValues.new.throw
            } else {
                $value
            }
        }
    }

}

our role App::Subcommander {
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

    method !parse-command-line(@args) {
        my %command-options;
        my @command-args;
        my $subcommand;

        my $type-resolver;
        my $canonicalizer;
        my $parser = OptionParser.new(:@args);

        for $parser.parse {
            when Option {
                my ( $name, $value ) = $parser.parse-option($type-resolver, ~$_);

                unless $value.defined {
                    try {
                        $value = $parser.demand-value;

                        CATCH {
                            when NoMoreValues {
                                SubcommanderException.new("Option '$name' requires a value").throw;
                            }
                        }
                    }
                }
                $name = $canonicalizer.canonicalize($name);
                my $type = $type-resolver.typeof($name);
                if $type-resolver.is-array($name) {
                    $type = $type.of;
                    unless %command-options{$name}:exists {
                        %command-options{$name} = Array[$type].new;
                    }
                    %command-options{$name}.push: self!fix-type($type, $value);
                } else {
                    %command-options{$name} = self!fix-type($type, $value);
                }
            }

            when Target {
                if $subcommand.defined {
                    @command-args.push: self!fix-type($type-resolver.typeof(+@command-args), ~$_);
                } else {
                    $subcommand = self!get-commands(){~$_};
                    if $subcommand !~~ Subcommand {
                        SubcommanderException.new("No such command '$_'").throw;
                    }
                    $type-resolver = TypeResolver.new(:command($subcommand));
                    $canonicalizer = OptionCanonializer.new(:command($subcommand));
                }
            }
        }

        return ( $subcommand, @command-args.item, %command-options.item );
    }
    

    method !get-commands {
        my %result;
        for self.^methods -> $method {
            if +$method.candidates > 1 && any($method.candidates.map({ $_ ~~ Subcommand })) {
                die "multis not yet supported by App::Subcommander";
            }
            if $method ~~ Subcommand {
                if %result{$method.command-name}:exists {
                    SubcommanderException.new("Duplicate definition of subcommand '$method.command-name()'").throw;
                }
                %result{$method.command-name} = $method;
            }
        }
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

    method !check-validity() {
        my @commands = self!get-commands.values;

        for @commands -> $cmd {
            for $cmd.signature.params -> $param {
                next if $param.invocant;
                next unless $param.positional;

                if $param.type ~~ Positional {
                    SubcommanderException.new("Positional array parameters are not allowed ($param.gist(), command = $cmd.command-name())").throw;
                }

                if $param.type ~~ Associative {
                    SubcommanderException.new("Positional hash parameters are not allowed ($param.gist(), command = $cmd.command-name())").throw;
                }
            }
        }
    }

    method run(@args) returns int {
        self!check-validity();

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
