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

my @allFields = ('AccountsLimit',
                 'HierarchicalStorageManagementEnabled',
                 'ValidFrom',
                 'BackupEnabled',
                 'MobileSyncAccountsLimit',
                 'ISyncAccountsLimit',
                 'ValidUntil',
                 'MobileSyncEnabled',
                 'InstallType',
                 'MAPIConnectorAccountsLimit',
                 'CrossMailboxSearchEnabled',
                 'IssuedOn',
                 'LicenseId',
                 'AttachmentConversionEnabled',
                 'IssuedToEmail',
                 'ResellerName',
                 'IssuedToName');

#                'HierarchicalStorageManagementEnabled=true
#                'ValidFrom=20060718160000Z
#                'BackupEnabled=true
#                'ValidUntil=20060925160000Z
#                'MobileSyncEnabled=true
#                'CrossMailboxSearchEnabled=true
#                'IssuedOn=20060719194749Z
#                 'LicenseId=caa739ac-03d4-4092-8bac-a6113abd88d2
#                 'AttachmentConversionEnabled=true

my %expected = ('AccountsLimit','-1',
                'MobileSyncAccountsLimit','-1',
                'ISyncAccountsLimit','-1',
                'MAPIConnectorAccountsLimit','-1',
                'InstallType','regular',
                'IssuedToEmail','qa@zimbra.com',
                'IssuedToName', 'zimbra qa');

my %allIndexOpts = ('pres'=>1,'eq'=>1,'approx'=>1,'sub'=>1);

my $undefined = 0;
my $exitCode = 0;

my $networkBuild = ($options{'targetBuild'} =~ /network/i);
if ($networkBuild == 1) {
    #NETWORK build
    print("NETWORK build\n");
    my @zmlicense = `su - zimbra -c "zmlicense -p"`;
    my %reality;
    foreach my $line (@zmlicense) {
	chomp $line;
	my ($key, $val) = split(/=/, $line);
	$reality{$key} = $val;
    }
    foreach my $key (keys %expected) {
	if($expected{$key} ne $reality{$key}) {
	    print("error in license key $key IS:\"$reality{$key}\" SB:\"$expected{$key}\"\n");
	    $exitCode++;
	}
    }
    my $res = `su - zimbra -c "zmlicense -c"`;
    chomp $res;
    if($res !~ /license is OK/) {
	print("error license status IS:\"$res\" SB:\"license is OK\"\n");
	$exitCode++;
    }
}
else {
    #FOSS build
    print("FOSS build\n");
    if( -e "/opt/zimbra/bin/zmlicense") {
        print("error found zmlicense in a FOSS build\n");
        $exitCode++;
    }
}
print("End ".basename($0)."\n");
exit($exitCode);

