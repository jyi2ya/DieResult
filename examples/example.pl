#!/usr/bin/env perl
use 5.036;
use utf8;
use warnings 'all';
use autodie ':all';
use open qw/:std :utf8/;
utf8::decode($_) for @ARGV;

use DieResult qw/wrap/;

sub read_to_string ($path) {
    open my $fh, '<:utf8', $path;
    local $/;
    scalar <$fh>
}

sub read_file($path) {
    my $collection = DieResult::Error->collection->context('failed to read config file');

    for my $retry (1 .. 3) {
        my $result = (wrap { read_to_string($path) })
            ->context("attempt $retry");

        if ($result->is_ok) {
            return $result->unwrap;
        } else {
            $collection->add($result->unwrap_err);
        }
    }

    die $collection;
}

sub load_config($path) {
    my $content = (wrap { read_file($path) })
        ->context("Failed to load application configuration")
        ->unwrap;
    $content;
}

sub load_config_with_debug_info($path) {
    my $content = (wrap { load_config($path) })
        ->attach("Config path: $path")
        ->attach("Expected format: TOML")
        ->unwrap;
    $content;
}

sub startup($config_path, $environment) {
    my $config = (wrap { load_config_with_debug_info($config_path) })
        ->context("Application startup failed")
        ->attach("Environment: $environment")
        ->unwrap;
    $config;
}

sub main {
    my $err = (wrap { startup('/cannot_read_this', 'development') })->unwrap_err;
    say $err;
}

main unless caller;
