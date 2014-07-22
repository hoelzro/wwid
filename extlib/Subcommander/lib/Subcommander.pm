module Subcommander:auth<hoelzro>:ver<0.0.1>;

my role Subcommand {
    has Str $.command-name is rw;
}

my role AppOption {
    has Str $.option-name is rw;
}

my class SubcommanderException is Exception {
    has Str $.message;

    method new(Str $message?) {
        self.bless(:$message);
    }
}

my class NoCommandGiven is SubcommanderException {
    method message { 'No command given' }
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

my class InvertedBool is Bool {
    has $.value;

    method Bool { !$.value }
}

our role TypeResolver {
    has %!named;
    has @!positional;

    multi submethod BUILD(:&command!) {
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

    multi submethod BUILD(::Application :$application) {
        my %attribute-setters;

        for $application.^attributes -> $attr {
            if $attr ~~ AppOption {
                my $name = $attr.name.subst(/^<[$@%&]> '!'/, '');
                %attribute-setters{$name} = {
                    :name($attr.option-name),
                    :type($attr.type),
                };
            }
        }

        for $application.^methods -> $method {
            if $method ~~ AppOption {
                my $type = $method.returns;
                if $type.WHERE == Mu.WHERE { # XXX dodgy
                    $type = Any;
                }
                %!named{$method.option-name} = $type;
            } elsif my $info = %attribute-setters{$method.name} {
                my $type = $info<type>;
                if $type.WHERE == Mu.WHERE {
                    $type = Any;
                }
                %!named{$info<name>} = $type;
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
            $name .= subst(/^ no '-'? /, '');

            if %!named{$name} ~~ Bool {
                return InvertedBool;
            }
        }
        %!named{$name}
    }

    proto method coerce($from, $to) { * }

    multi method coerce(Str $from, Any:U $to) {
        my $name = $to.^name;
        my $value = $from;

        if $from !~~ $to {
            # $value = try $from."$name'(); didn't work, look into this
            try {
                $value = $from."$name"();
                CATCH {
                    default {
                        SubcommanderException.new("Failed to convert '$from'").throw;
                    }
                }
            }
        }
        $value
    }

    multi method coerce(Str $from, InvertedBool:U $to) {
        !$from.Bool
    }
}

our role OptionCanonicalizer {
    has %!canonical-names;

    multi submethod BUILD(:&command!) {
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

    multi submethod BUILD(::Application :$application) {
        my %attribute-setters;
        for $application.^attributes -> $attr {
            if $attr ~~ AppOption {
                my $name = $attr.name.subst(/^<[$@%&]> '!'/, '');
                %attribute-setters{$name} = $attr.option-name;
            }
        }

        for $application.^methods -> $method {
            if $method ~~ AppOption {
                %!canonical-names{$method.option-name} = $method.name;
            } elsif my $name = %attribute-setters{$method.name} {
                %!canonical-names{$name} = $method.name;
            }
        }
    }

    method canonicalize(Str $name is copy) returns Str {
        unless %!canonical-names{$name}:exists {
            $name .= subst(/^ no '-'? /, '')
        }
        %!canonical-names{$name} // $name
    }
}

our role OptionParser {
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
        $arg ~~ /^ '--'/ && !self!is-option-terminator($arg)
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

        if $type-resolver.typeof($key) ~~ Bool {
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

our class DefaultTypeResolver does TypeResolver {}
our class DefaultOptionCanonicalizer does OptionCanonicalizer {}
our class DefaultOptionParser does OptionParser {}

our role Application {
    method type-resolver(*@args, *%kwargs) { DefaultTypeResolver.new(|@args, |%kwargs) }
    method option-parser(*@args, *%kwargs) { DefaultOptionParser.new(|@args, |%kwargs) }
    method option-canonicalizer(*@args, *%kwargs) { DefaultOptionCanonicalizer.new(|@args, |%kwargs) }

    my sub extract-attr-name(Str $name --> Str) {
        $name.subst(/^<[$@%&]> '!'/, '')
    }

    method !is-valid-app-option(Str $name) returns Bool {
        my @names = (
            self.^methods.grep({ $_ ~~ AppOption }).map(*.name),
            self.^attributes.grep({ $_ ~~ AppOption }).map({ extract-attr-name(.name) }),
        );

        ?@names.first(* eq $name)
    }

    method !parse-command-line(@args) {
        my %command-options;
        my @command-args;
        my $subcommand;

        my $type-resolver = $.type-resolver(:application(self));
        my $canonicalizer = $.option-canonicalizer(:application(self));
        my $parser = $.option-parser(:@args);

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
                # type resolution must precede name canonicalization (due to things like --no-flag)
                my $type = $type-resolver.typeof($name);
                $name = $canonicalizer.canonicalize($name);

                if $subcommand.defined {
                    if $type-resolver.is-array($name) {
                        $type = $type.of;
                        unless %command-options{$name}:exists {
                            %command-options{$name} = Array[$type].new;
                        }
                        %command-options{$name}.push: $type-resolver.coerce($value, $type);
                    } else {
                        %command-options{$name} = $type-resolver.coerce($value, $type);
                    }
                } else {
                    unless self!is-valid-app-option($name) {
                        SubcommanderException.new("Unrecognized option '$name'").throw;
                    }

                    my $container     := self."$name"();
                    my $container-type = $container.VAR;

                    if $container-type ~~ Positional { # XXX is this the right test?
                        $type = $container-type.of;
                        if $type.WHERE == Mu.WHERE { # XXX dodgy
                            $type = Any;
                        }
                        # XXX we're assuming it's something that supports push
                        $container.push: $type-resolver.coerce($value, $type);
                    } else {
                        $container = $type-resolver.coerce($value, $type);
                    }
                }
            }

            when Target {
                if $subcommand.defined {
                    @command-args.push: $type-resolver.coerce(~$_, $type-resolver.typeof(+@command-args));
                } else {
                    $subcommand = self!get-commands(){~$_};
                    if $subcommand !~~ Subcommand {
                        SubcommanderException.new("No such command '$_'").throw;
                    }
                    $type-resolver = $.type-resolver(:command($subcommand));
                    $canonicalizer = DefaultOptionCanonicalizer.new(:command($subcommand));
                }
            }
        }

        unless $subcommand {
            NoCommandGiven.new.throw;
        }

        return ( $subcommand, @command-args.item, %command-options.item );
    }

    method !get-commands {
        my %result;
        for self.^methods -> $method {
            if +$method.candidates > 1 && any($method.candidates.map({ $_ ~~ Subcommand })) {
                die "multis not yet supported by Subcommander";
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
                die 'multis not yet supported by Subcommander';
            }

            self!check-args($command, $args, $cmd-options);

            $command(self, |@($args), |%($cmd-options));

            return 0;

            CATCH {
                when SubcommanderException {
                    unless $_ ~~ NoCommandGiven {
                        $*ERR.say: $_.message;
                    }
                    self.show-help;
                    return 1;
                }
            }
        }
    }

    method show-help {
        $*ERR.say: "Usage: $*PROGRAM_NAME [command]";
        my %commands    = %(self!get-commands);
        my $max-cmd-len = [max] %commands.keys>>.chars; # XXX graphemes?
        my $format      = "%{$max-cmd-len}s\t%s";

        for %commands.keys.sort -> $name {
            my $command = %commands{$name};
            my $description = ~$command.WHY // '';
            $*ERR.say: sprintf($format, $name, $description);
        }
    }
}

multi trait_mod:<is>(Routine $r, :subcommand($name)! is copy) is export {
    if $name ~~ Bool {
        $name = $r.name;
    }
    $r does Subcommand;
    $r.command-name = $name;
}

multi trait_mod:<is>(Routine $r, :option($name)! is copy) is export {
    if $name ~~ Bool {
        $name = $r.name;
    }

    $r does AppOption;
    $r.set_rw();
    $r.option-name = $name;
}

multi trait_mod:<is>(Attribute $a, :option($name)! is copy) is export {
    if $name ~~ Bool {
        $name = $a.name.subst(/^<[$@%&]> '!'/, '');
    }
    $a does AppOption;
    $a.set_rw();
    $a.option-name = $name;
}
