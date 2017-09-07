#!/usr/bin/perl

use strict;

use Getopt::Long;
use File::Basename;

our %options = ();
my @allNames = ('bits', 'machine', 'OS', 'build', 'branch',
                'baseBuild', 'targetBuild');

$| = 1;

## strictCheck = 1 check for values in expected config
##             = 0 check whether isConfig{key} exists
my $strictCheck = 1;

print("Start ".basename($0)."...\n");
GetOptions (\%options, 'bits=s', 'machine=s', 'OS=s', 'build=s',
                       'branch=s', 'baseBuild=s', 'targetBuild=s');

#foreach my $opt (keys %options) {
#   print "options{$opt}=$options{$opt}\n";
#}

my $exitCode = 0;
my $paramToCheck = "smtpd_use_tls";
my $res = `su - zimbra -c "postconf $paramToCheck 2>&1"`;
if (($?>>8) != 0) {
    print("error executing postconf, exit code ".($? >> 8)."\n");
    $exitCode++;
}
else {
    my ($name, $val) = split('=', $res);
    $val =~ s/^\s*(.*?)\s*$/$1/;

    if($val ne "yes") {
        $val = "null" if !$val;
        print("error wrong postfix configuration $paramToCheck IS:$val SB:yes\n");
        $exitCode++;
    }
}
print("End ".basename($0)."\n");
exit($exitCode);


