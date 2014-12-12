#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Prancer qw(config);

use File::Basename ();
use Prancer::Plugin::Xslate qw(render);

sub main {
    # figure out where exist to make finding config files possible
    my (undef, $root, undef) = File::Basename::fileparse($0);

    # this just returns a prancer object so we can get access to configuration
    # options and other awesome things like plugins.
    my $app = Prancer->new("${root}/foobar.yml");

    # in here we get to initialize things!
    my $plugin = Prancer::Plugin::Xslate->load();
    $plugin->path($root);
    $plugin->add_function("baz", sub { return "barfoo"; });
    $plugin->add_module("Digest::SHA1", ['sha1_hex']);
    $plugin->add_module("Data::Dumper");

    print render("foobar.tx", {
        "foo" => "bar"
    });

    return;
}

main(@ARGV) unless caller;

1;
