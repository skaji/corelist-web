#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use CPAN::Meta::Prereqs;
use Capture::Tiny qw(capture_merged);
use Email::MIME;
use Email::Sender::Simple ();
use File::Spec;
use File::pushd qw(pushd);
use FindBin qw($Bin);
use MetaCPAN::API;
use Module::CPANfile;
use POSIX qw(strftime);
use Sys::Hostname qw(hostname);
use constant DEBUG => $ENV{UPDATE_DEBUG};
sub debug { DEBUG and warn "[DEBUG] @_\n" }

main() unless caller();

sub main {
    my $module   = 'Module::CoreList';
    my $cpanfile = File::Spec->catfile($Bin, 'cpanfile');

    my $original_prereqs = Module::CPANfile->load($cpanfile)->prereqs;
    my $current_version  = $original_prereqs->as_string_hash->{runtime}{requires}{$module}
        // die "ERROR missing verison of $module";
    my $latest_version   = latest_version_of($module);

    debug "current version of $module: $current_version";
    debug "latest version of $module: $latest_version";

    if ($current_version >= $latest_version) {
        debug "nothing to do.";
        return;
    }

    my $new_prereqs = $original_prereqs->with_merged_prereqs(
        CPAN::Meta::Prereqs->new({
            runtime => { requires => {$module => $latest_version} }
        })
    );

    Module::CPANfile->from_prereqs($new_prereqs->as_string_hash)->save($cpanfile);
    debug "updated cpanfile.";

    {
        my $guard = pushd $Bin;
        my $ok;
        my $merged = capture_merged {
            $ok = !system 'carton', 'install';
        };
        debug "carton install output:";
        debug $_ for split /\n/, $merged;
        email($merged, $ok);
        debug "sending email done.";
        if ($ok) {
            debug "do restart.";
            system 'sh', 'restart.sh';
        } else {
            debug "carton install exits abnormally, thus skip restarting.";
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


sub email {
    my ($body, $ok) = @_;

    my $to   = `git config user.email`     or die;
    my $from = sprintf '%s@%s', scalar(getpwuid $>), hostname;
    $to =~ s/\r?\n//;
    debug "email to: $to";
    debug "email from: $from";

    my $now     = strftime("%Y-%m-%d %H:%M:%S %Z", localtime);
    my $subject = ($ok ? 'SUCCESS' : 'FAILED') . ": carton install ($now)";
    debug "email subject: $subject";

    my $email = Email::MIME->create(
        header => [
            To      => $to,
            From    => $from,
            Subject => $subject,
        ],
        body => $body,
    );
    Email::Sender::Simple->send($email);
}


__END__

=head1 SYNOPSIS

  $ crontab -e
  PATH=/set/appropriate/path
  0 0 * * * perl -I/path/to/corelist-web/local/lib/perl5 /path/to/corelist-web/update_module_corelist.pl

=cut
