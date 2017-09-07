#!/usr/bin/perl -w

use strict;
use Net::SMTP;
use Getopt::Long;
use Pod::Usage;
use MIME::Base64;
use Authen::SASL;

my ($opt_help, $opt_verbose, $opt_server, $opt_recipients, $opt_sender, $opt_auth_password, $opt_auth_user);

GetOptions("help" => \$opt_help,
	   "verbose" => \$opt_verbose,
	   "auth_user=s" => \$opt_auth_user,
	   "auth_password=s" => \$opt_auth_password,
	   "address=s" => \$opt_server,
	   "recipient=s@" => \$opt_recipients,
	   "sender=s" => \$opt_sender) || pod2usage(2);

pod2usage(1) if ($opt_help);
pod2usage(-msg => "No SMTP server specified") if (!defined($opt_server));
pod2usage(-msg => "No recipients specified") if (!defined($opt_recipients));
$opt_sender = "" if (!defined($opt_sender));
$opt_auth_password = "" if (!defined($opt_auth_password));

pod2usage(-msg => "No input files specified") if ($#ARGV < 0);

my $smtp = Net::SMTP->new("$opt_server") || die;
$smtp->debug($opt_verbose);

if (defined($opt_auth_user)) {
	print "Authenticating using user[$opt_auth_user] password[$opt_auth_password] ...\n";
	$smtp->auth($opt_auth_user, $opt_auth_password) || die($smtp->message());
}

for (my $i = 0; $i <= $#ARGV; $i++) {
	$smtp->reset();
	$smtp->mail("<$opt_sender>") || die($smtp->message());
	foreach my  $recipient (@$opt_recipients) {
	    $smtp->to("<$recipient>")  || die($smtp->message());
	}
	$smtp->data();
	open(DATA, $ARGV[$i]) || die($ARGV[$i] . ": $!");
	while (<DATA>) {
	    $smtp->datasend($_);
	}
    close(DATA);
}
$smtp->dataend();

__END__

=head1 NAME

    smtpclient - since telnet to port 25 gets old after a while

=head1 SYNOPSUS

    smtpclient [options] [datafile ...]

      Options:

        -h --help        usage message
        -a --address     SMTP server name or address
        -r --recipient   envelope recipient email address
        -s --sender      enveloper sender email address
        --auth_user      (optional) Auth (non-TSL) user name
        --auth_password  (optional) Auth (non-TSL) user password
        -v --verbose     show SMTP transaction
	

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--address>

Name or address of SMTP server to send message through.  This option
must be specified.  You can also specify host:port if you need to
connect to a different port.

=item B<--recipient>

Envelope recipient address.  Specify it without the angle brackets <>.
For multiple recipients, repeat this option on the command line.  This
option must occur atleast once.

=item B<--sender>

Envelope sender address.  Optional, defaults to <>.

=item B<--verbose>

Debug output of SMTP transaction.

=item B<--auth_user>

Authentication user name.  Specify the auth_user and auth_password to
authenticate.  If not specified, authentication will not be used.

=item B<--auth_password>

Authentication user password.  Specify the auth_user and auth_password to
authenticate.  If not specified and user name is specified, then a blank
password will be used.

=item B<datafile>

A message with DATA from datafile is sent for each datafile specified.

=back

=head1 DESCRIPTION

This program connects to a SMTP server, and sends a message per
envelope arguments -r and -s.

=cut

