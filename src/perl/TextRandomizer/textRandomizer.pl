#!/usr/bin/perl

use strict;


# usage check
#
# textRandomizer.pl <inputFile.txt >outputFile.txt
#
# Also, uppercase chars are converted to random uppercase chars (same with lowercase)
# 	and numbers are converted to random numbers
#	and all non-alphanumeric characters are left as-is
#
#
my $COMMAND_LINE="$0 @ARGV";

sub randomChar() {

	$_[rand @_];
		
}

my @upperCase = ("A".."Z");
my @lowerCase = ("a".."z");
my @digits = (0..9);

while ( <> ) {
	
	my $len = length($_);
	
	for (my $index = 0; $index < $len; $index++) {
		my $char = substr($_, $index, 1);
		
		# print $char;
		if ( $char =~ /[A-Z]/ ) {
			#print "Upper Case: $char ... ";
			$char = &randomChar(@upperCase);
		}
		if ( $char =~ /[a-z]/ ) {
			#print "Lower Case: $char ... ";
			$char = &randomChar(@lowerCase);
		}
		if ( $char =~ /[0-9]/ ) {
			#print "Numbers: $char ... ";
			$char = &randomChar(@digits);
		}
		
		print $char;
	}
		
}


