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

my $exitCode = 0;
my $dirInfo = `ls -lLd /opt/zimbra/tomcat`;
my @ownership = (split(' ', $dirInfo))[2..3];
my $reality = join(':', @ownership);
my $expected = $options{'OS'} =~ /MACOSX/ ? 'root:wheel' : 'root:root';
if($reality ne $expected) {
        print("error wrong /opt/zimbra/apache ownership IS:\"$reality\" SB:\"$expected\"\n");
        $exitCode++;
}
print("End ".basename($0)."\n");
exit($exitCode);


