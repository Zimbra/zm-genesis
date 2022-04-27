#!/bin/env perl
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#
use Cwd;
use File::Spec; 
use Pod::Usage; 
use File::Temp qw/ tempfile tempdir /;
use Sys::Hostname;
use MIME::Base64 ();

my $origdir = getcwd;
my $smtpDir = File::Spec->catfile('/opt','qa','smtpservice','bin');
my @jarFile = qw(zimbracommon.jar zimbrastore.jar javamail-1.4.3.jar commons-httpclient-3.0.jar commons-cli-1.2.jar log4j-core-2.17.1.jar log4j-api-2.17.1.jar commons-logging.jar dom4j-1.5.jar activation.jar);

# Can't use getopt for trapping -m.. roll a customer processor

print @ARGV;
my @MARGV;
my $opt_machine;
my $opt_file;

while(my $current = shift @ARGV) {  
  if($current eq '-m' || $current eq '--machine') {
    if(scalar @ARGV > 0) {
      $opt_machine = shift @ARGV;
    }
  }
  elsif($current eq '-f' || $current eq '--file') {
    if(scalar @ARGV > 0) {
      $opt_file = shift @ARGV;
    }
  }
  else {
    push @MARGV, $current;
  }
}

print @MARGV, "\n";

#
# Do STAF file transfer if 
#
if($opt_machine) {
 ($fh, $filename) = tempfile(UNLINK => 1);
  $fh->close();
  my $host = hostname;
  my $sstring =  "staf $opt_machine FS COPY FILE $opt_file TOFILE $filename TOMACHINE $host";
  `bash -l -c '$sstring'`;
  $opt_file = $filename;
}

chdir $smtpDir or die "cannot chdir to $smtpDir: $!";

my $jterm = ''; #figure out what terminator to use
if( $^O eq 'MSWin32' ) {
	$jterm = ';';
}
else {
	$jterm = ':';
}

my $command = "java -classpath ".join($jterm, @jarFile)." com.zimbra.cs.util.SmtpInject -v -T @MARGV -f $opt_file";
system "$command";
open(STATUS, "$command 2>&1 |") || die "can't fork: $!";
my @smtp_result = <STATUS>;
close STATUS || die "bad javamail: $! $?";
my $smtp_result = MIME::Base64::encode(join('', @smtp_result));
print $smtp_result;


chdir $origdir;

exit 0;

__END__

=head1 NAME

    smtp - yet another smtp email injection tool

=head1 SYNOPSUS

    smtpclient [options] [datafile ...]

      Options:

        -h --help              usage message
        --a,--address <arg>    smtp server (default localhost)
        -f,--file <arg>        rfc822/MIME formatted text file 
        -m,--machine <arg>     machine where text file sits
        -p,--password <arg>    password for SMTP auth
        -r,--recipient <arg>   envelope recipients (rcpt to)
        -s,--sender <arg>      envelope sender (mail from)
        -t,--tls               use TLS
        -T,--trace             trace server/client traffic
        -u,--username <arg>    username for SMTP auth
        -v,--verbose           show provided options


	

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=back

=head1 DESCRIPTION



=cut

