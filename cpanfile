#!perl

requires 'Plack';
requires 'Amon2::Lite';
requires 'JSON';
requires 'Module::CoreList' => 2.79;

on test => sub {
    requires 'Test::WWW::Mechanize::PSGI';
};