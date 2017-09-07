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

my %expectedConfig = ('zimbraRemoteManagementCommand'=>'/opt/zimbra/libexec/zmrcd',
		      'zimbraRemoteManagementPort'=>'22',
		      'zimbraRemoteManagementPrivateKeyPath'=>'/opt/zimbra/.ssh/zimbra_identity',
		      'zimbraRemoteManagementUser'=>'zimbra'
		      );
#my @servers = `su - zimbra -c "zmprov gas"`;
#if (($?>>8) != 0) {
#    print("error command \"zmprov gas\" failed, exit code ".($? >> 8)."\n");
#    exit(1);
#}

my $hn = `su - zimbra -c "zmlocalconfig -m nokey zimbra_server_hostname"`;
if (($?>>8) != 0) {
    print("error cannot find zimbra server hostname, exit code ".($? >> 8)."\n");
    exit(1);
}
my @servers = ($hn);
my $undefined = 0;
my @res;
my $exitCode = 0;

foreach my $server (@servers) {
    my %isConfig;
    chomp $server;
    @res = `su - zimbra -c "zmprov gs $server | grep zimbraRemoteManagement"`;
    foreach my $line (@res) {
        next if $line =~ /^$/;
	chomp $line;
	$line =~ /^(.*):\s+(.*)$/;
	$isConfig{$1} = $2;
    }
    foreach my $requiredParam (keys %expectedConfig) {
	if (!exists $isConfig{$requiredParam}) {
	    print("error server $server: undefined $requiredParam\n");
	    $undefined++;
	}
        elsif ($strictCheck && 
	       ($isConfig{$requiredParam} ne $expectedConfig{$requiredParam})) {
            print("error server $server: $requiredParam IS:$isConfig{$requiredParam}".
                  " SB:$expectedConfig{$requiredParam}\n");
            $undefined++;
	}
    }
}
if($undefined) {
    print("found $undefined errors\n");
    $exitCode++;
}

print("End ".basename($0)."\n");
exit($exitCode);


