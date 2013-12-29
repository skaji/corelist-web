use strict;
use warnings;
use 5.010001;
use File::Basename;
use Amon2::Lite;
use Module::CoreList;
use Plack::Builder;


our $VERSION = '0.02';

__PACKAGE__->template_options(
    function => { module_corelist_version => sub { Module::CoreList->VERSION } },
);

get '/' => sub {
    my ($c) = @_;

    my $module = $c->req->param('module') // 'Module::CoreList';
    my @data;
    for my $v (grep {!/000$/} reverse sort keys %Module::CoreList::version) {
        my $modver = $Module::CoreList::version{$v}->{$module};
        next unless $modver;
        push @data, {perl => $v, module => $modver};
    }
    my $cpan_url = "https://metacpan.org/pod/$module";

    $c->render('module.tt', {data => \@data, module => $module, cpan_url => $cpan_url});
};

get '/version-list' => sub {
    my ($c) = @_;
    my @data = map {+{
        perl => $_,
        date => $Module::CoreList::released{$_}
    }} grep {!/000$/} reverse sort keys %Module::CoreList::released;
    $c->render( 'version-list.tt', {data => \@data} );
};

get '/v/{version}' => sub {
    my ($c, $args) = @_;
    my $version = $args->{version} // die;
    my %modules = %{$Module::CoreList::version{$version}};
    # $params{module_keys} = [sort keys %modules];
    $c->render('version.tt', {version => $version, modules => \%modules});
};


my $amon2 = __PACKAGE__->to_app();

builder {
    enable 'Static', path => qr{^/static/}, root => '.';
    $amon2;
};


