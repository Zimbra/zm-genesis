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

#zimbraRemoteManagementCommand: /opt/zimbra/libexec/zmrcd
#zimbraRemoteManagementPort: 22
#zimbraRemoteManagementPrivateKeyPath: /opt/zimbra/.ssh/zimbra_identity
#zimbraRemoteManagementUser: zimbra

my $exitCode = 0;
my %expectedAccounts = ();
my %expectedRemoteConfig = ('zimbraRemoteManagementCommand'=>'/opt/zimbra/libexec/zmrcd',
			    'zimbraRemoteManagementPort'=>'22',
			    'zimbraRemoteManagementPrivateKeyPath'=>'/opt/zimbra/.ssh/zimbra_identity',
			    'zimbraRemoteManagementUser'=>'zimbra');


foreach my $config (keys %expectedRemoteConfig) {
    my $cfg = `su - zimbra -c "zmprov gcf $config"`;
    chomp $cfg;
    my $val = (split(/ /, $cfg))[1];
    if ($val ne $expectedRemoteConfig{$config}) {
        $val = "None" if $val eq "";
	$exitCode++;
	print("error wrong remote management configuration $config IS:$val SB:$expectedRemoteConfig{$config}\n");
    }
}

if($exitCode) {
    print("found $exitCode errors\n");
}

print("End ".basename($0)."\n");
exit($exitCode);


