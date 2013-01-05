#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Capture::Tiny qw(capture_merged);
use Email::Sender::Simple qw(sendmail);
use Email::Simple::Creator;
use Email::Simple;
use File::Spec;
use File::chdir;
use FindBin qw($Bin);
use MetaCPAN::API;
use Perl6::Slurp qw(slurp);
use POSIX ();

main() unless caller();

sub main {
    my $module   = 'Module::CoreList';
    my $cpanfile = File::Spec->catfile($Bin, 'cpanfile');
    my $tt_file  = File::Spec->catfile($Bin, qw(tmpl include footer.tt));

    my $current_version = current_version_of(
        module   => $module,
        cpanfile => $cpanfile,
    );
    my $latest_version  = latest_version_of($module);

    return if $current_version >= $latest_version;

    update_tt_file( tt_file  => $tt_file,  version => $latest_version);
    update_cpanfile(cpanfile => $cpanfile, version => $latest_version);

    {
        local $CWD = $Bin;
        my $ok;
        my $merged = capture_merged {
            $ok = !system 'carton', 'install', '--no-color';
        };
        email($merged, $ok);
        if ($ok) {
            system 'sh', 'restart.sh';
        }
    }
    return;
}


sub latest_version_of {
    my $mod = shift;
    my $cpan = MetaCPAN::API->new;
    $mod =~ s/::/-/g;
    return $cpan->release(distribution => $mod)->{version};
}

sub current_version_of {
    my %arg = ref $_[0] ? %{$_[0]} : @_;
    my $cpanfile = delete $arg{cpanfile} or die;
    my $module   = delete $arg{module}   or die;
    for (slurp $cpanfile) {
        if (/$module.*?([\d.]{2,})/) {
            return $1;
        }
    }
    die;
}

sub email {
    my ($body, $ok) = @_;

    my $to   = `git config user.email`     or die;
    my $from = `whoami` . '@' . `hostname` or die;
    s/\r?\n//g for $to, $from;

    my $now     = POSIX::strftime("%Y-%m-%d %H:%M:%S %Z", localtime);
    my $subject = ($ok ? 'SUCCESS' : 'FAILED') . ": carton install ($now)";

    my $email = Email::Simple->create(
        header => [
            To      => $to,
            From    => $from,
            Subject => $subject,
        ],
        body => $body,
    );
    sendmail($email);
}

sub update_tt_file {
    my %arg = ref $_[0] ? %{$_[0]} : @_;
    my $tt_file = delete $arg{tt_file} or die;
    my $version = delete $arg{version} or die;
    my @content = slurp $tt_file;
    open my $out, '>', $tt_file or die "$!";
    for (@content) {
        s/(web interface.*?)([\d.]{2,})/$1$version/;
        print {$out} $_;
    }
    return;
}

sub update_cpanfile {
    my %arg = ref $_[0] ? %{$_[0]} : @_;
    my $cpanfile = delete $arg{cpanfile} or die;
    my $version  = delete $arg{version}  or die;
    my @content  = slurp $cpanfile;
    open my $out, '>', $cpanfile or die $!;
    for (@content) {
        s/(Module::CoreList.*?)([\d.]{2,})/$1$version/;
        print {$out} $_;
    }
    return;
}

__END__

=head1 SYNOPSIS

  $ crontab -e
  PATH=/set/appropriate/path
  0 0 * * * perl -I/path/to/corelist-web/local/lib/perl5 /path/to/corelist-web/update_module_corelist.pl

=cut
