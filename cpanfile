requires 'Amon2::Lite';
requires 'CPAN::Meta::Prereqs';
requires 'Capture::Tiny';
requires 'Email::MIME';
requires 'Email::Sender::Simple';
requires 'File::pusd';
requires 'List::MoreUtils';
requires 'MetaCPAN::API';
requires 'Module::CPANfile';
requires 'Module::CoreList', '3.02';
requires 'Plack';
requires 'Plack::Middleware::ReverseProxy';
requires 'Starman';

on test => sub {
    requires 'Test::WWW::Mechanize::PSGI';
};
