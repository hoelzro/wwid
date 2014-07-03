use v6;
use Test;

use App::Subcommander;

plan 1;

my class CustomException is Exception {
}

my class App does App::Subcommander {
    method exceptional is subcommand {
        CustomException.new.throw;
    }
}

my $*ERR = open(IO::Spec.devnull, :w);

throws_like({
    App.new.run(['exceptional']);
}, CustomException);
