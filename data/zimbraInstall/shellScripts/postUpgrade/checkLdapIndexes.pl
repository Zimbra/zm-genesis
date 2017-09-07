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

my $slapdConf = "/opt/zimbra/conf/slapd.conf";
my @allIndexes = ('objectClass',
                  'zimbraForeignPrincipal',
                  'zimbraId',
                  'zimbraVirtualHostname',
                  'zimbraMailCatchAllAddress',
                  'zimbraMailDeliveryAddress',
                  'zimbraMailForwardingAddress',
                  'zimbraMailAlias',
                  'zimbraDomainName',
                  'zimbraShareInfo',
                  'uid',
                  'mail',
                  'cn',
                  'displayName',
                  'sn',
                  'gn',
                  'zimbraCalResSite',
                  'zimbraCalResBuilding',
                  'zimbraCalResFloor',
                  'zimbraCalResRoom',
                  'zimbraCalResCapacity',
                  'entryUUID',
                  'entryCSN');

my %allIndexOpts = ('pres'=>1,'eq'=>1,'approx'=>1,'sub'=>1);

my $undefined = 0;
my $exitCode = 0;

open FILE, "$slapdConf" or die "Couldn't open file: $!";
my @content;
while (<FILE>) {
    chomp;
    push(@content, $_) if /^index/;
}
close FILE;
#print "cnt=@content\n";

foreach my $index (@allIndexes) {
    my $found = 0;
    my $crt;
    foreach my $line (@content) {
#	if($line =~ /^index\s+$index\s+(\b(pres|eq|approx|sub)\b)\s*/) {
	if($line =~ /^index\s+$index\s+(\S+)\s*/) {
#	    print "found $line, $1\n";
	    my @crtOpts = split(/,/, $1);
            my $isValid = 1;
            foreach my $opt (@crtOpts) {
                if (! exists $allIndexOpts{$opt}) {
#		    my @k=keys %allIndexOpts;
#		    print("notvalid $opt, keys=@k\n");
                    $isValid = 0;
		    $crt = $line;
                    last;
                }
            }
            if ($isValid == 1) {
		$found = 1;
		$crt = $line;
		last;
	    }
	}
    }
    if ($found == 0) {
	print("error ldap index $index not found IS:\"$crt\" SB:\"index\\s+$index\\s+\\S*(pres|eq|approx|sub)+\"\n");
	$exitCode++;
    }
}
#if ($exitCode == 0) {
#    open FILE, "$confDir/$files[1]" or die "Couldn't open file: $!";
#    my @content = <FILE>;
#    close FILE;
#    chomp($content[0]);
#    chomp($content[$#content]);
#    if (($content[0] ne $keyHead) || ($content[$#content] ne $keyTail)) {
#        print("error invalid cert file $confDir/$files[1]\n");
#        $exitCode++;
#    }
#}

print("End ".basename($0)."\n");
exit($exitCode);

