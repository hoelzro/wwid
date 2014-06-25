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

throws_like({
    App.new.run(['exceptional']);
}, CustomException);
