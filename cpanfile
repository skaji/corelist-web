#!perl

requires 'Plack';
requires 'Amon2::Lite';
requires 'Module::CoreList' => '2.97';
requires 'Starman';
requires 'List::MoreUtils';
requires 'Plack::Middleware::ReverseProxy';

# for update_module_corelis.pl
requires 'Capture::Tiny';
requires 'Email::Sender';
requires 'File::chdir';
requires 'MetaCPAN::API';
requires 'Perl6::Slurp';

on test => sub {
    requires 'Test::WWW::Mechanize::PSGI';
};
