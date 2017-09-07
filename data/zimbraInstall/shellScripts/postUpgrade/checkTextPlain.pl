#!/usr/bin/perl

use strict;

use Getopt::Long;
use File::Basename;

our %options = ();
my @allNames = ('bits', 'machine', 'OS', 'build', 'branch',
                'baseBuild', 'targetBuild');
my %expected = ();
$expected{'zimbraMimeType'}{'text/plain'} = 0;
$expected{'cn'}{'text/plain'}= 0;
$expected{'objectClass'}{'zimbraMimeEntry'} = 0;
$expected{'zimbraMimeIndexingEnabled'}{'TRUE'} = 0;
$expected{'zimbraMimeHandlerClass'}{'TextPlainHandler'} = 0;
$expected{'zimbraMimeFileExtension'}{'txt'} = 0;
$expected{'zimbraMimeFileExtension'}{'text'} = 0;
$expected{'description'}{'Plain Text Document'} = 0;

$| = 1;

## strictCheck = 1 check for values in expected config
##             = 0 check whether isConfig{key} exists
my $strictCheck = 1;

print("Start ".basename($0)."...\n");
GetOptions (\%options, 'bits=s', 'machine=s', 'OS=s', 'build=s',
                       'branch=s', 'baseBuild=s', 'targetBuild=s');

my $exitCode = 0;
my $url = `su - zimbra -c "zmlocalconfig ldap_url"`;
my ($name, $ldapUrl) = split('=', $url);
chomp $ldapUrl;
my $ldapPass = `su - zimbra -c "zmlocalconfig -s -m nokey ldap_root_password"`;
chomp $ldapPass;
my %reality;
my @text = `su - zimbra -c "ldapsearch -H $ldapUrl -x -w $ldapPass -D uid=zimbra,cn=admins,cn=zimbra -b cn=mime,cn=config,cn=zimbra  cn=text/plain"`;
foreach my $line (@text) {
    my ($key, $val) = split(/:/, $line);
    chomp $val;
    $val =~ s/^\s*//;
    if (! exists $reality{$key}{$val}) {
       $reality{$key}{$val} = 0;
    }
    else {
       #error: duplicate attr
    }
}
foreach my $key (keys %expected) {
    foreach my $val (keys %{$expected{$key}}) {
        #my $expect = join(' or ', @{$expected{$key}});
        if(! exists $reality{$key}{$val}) {
           if(grep(/(^|\.)$val/, keys %{$reality{$key}}) == 0) {
               my $exp = join(' & ', sort keys %{$expected{$key}});
               my $got = 'missing';
               $got = join(' or ', sort keys %{$reality{$key}}) if ! exists $reality{$key};
               print("error wrong ldap configuration for text/plain $key IS:$got SB:$exp\n");
               $exitCode++;
           }
        }
    }
}
print("End ".basename($0)."\n");
exit($exitCode);


