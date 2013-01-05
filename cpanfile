#!perl

requires 'Plack';
requires 'Amon2::Lite';
requires 'JSON';
requires 'Module::CoreList' => '2.79';
requires 'Starman';

# for update_module_corelis.pl
requires 'Capture::Tiny';
requires 'Email::Sender';
requires 'File::chdir';
requires 'MetaCPAN::API';
requires 'Perl6::Slurp';

on test => sub {
    requires 'Test::WWW::Mechanize::PSGI';
};
