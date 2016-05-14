#!/usr/bin/perl

###################
# check script to check for CPU Util
#  usage on linux.  The base is 
#  using the sar command
#
# The script is maintained at https://github.com/throwsb/nagios-checks/
#
# Licensed under GNU GPLv3 - see the LICENSE file in the git repository.
#
#  Created by David Worth 24-Feb-2016
#  version 0.10
###################

use POSIX;
use Getopt::Std;
use Sys::Hostname;

$TRUE = 1;
$FALSE = 0;
$STATUS_OK=0;
$STATUS_WARN=1;
$STATUS_CRIT=2;
$STATUS_UNKNOWN=3;

($MYNAME = $0) =~ s/.*\///;
($HOST) = split /\./, hostname();
$DEBUG=$FALSE;
$STATUS = "UNKNOWN";
$CRITICAL = "95";
$WARNING = "85";
$SWAP=$FALSE;
$DISPLAY_STATUS;
$PROB_STATUS;

$SAR="/usr/bin/sar";
$SARINT=1;
$SARCOUNT=5;
$SAROPTS=" 1 10";
$CPU;
$USR=0;
$NICE=0;
$SYSTEM=0;
$IOWAIT=0;
$STEAL=0;
$IDLE=0;
$CPU_USED=0;
$CPUStat="";
$UNIT="%";


getopts('dc:w:C:W:') or Usage();
$DEBUG = $TRUE if ($opt_d);
if($opt_w) {
	$WARNING = $opt_w;
	$WARNING =~ m/^[0-9]+$/ or (print "\nERROR: WARNING is not an unsigned digit: $WARNING \n" and  Usage());
}
if($opt_c) {
	$CRITICAL = $opt_c;
	$CRITICAL =~ m/^[0-9]+$/ or (print "\nERROR: CRITICAL is not an unsigned digit: $CRITICAL \n" and  Usage());
}
if($opt_C) {
	$SARCOUNT = $opt_C;
	$SARCOUNT =~ m/^[0-9]+$/ or (print "\nERROR: Count is not an unsigned digit: $SARCOUNT \n" and  Usage());
}


if ($WARNING >= $CRITICAL) {
  print ("\n Warning is less than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  Usage();
}


sub Usage {

  warn <<EOF;
  
  $MYNAME - Checks the CPU utilization across all CPU's on a server
  			and returns the percentage used.  It will also provide the 
  			following statistics:
  			
  			%CPU - Total percentage of CPU utilization.
  			%user - Percentage of CPU utilization at the user level.
  			%system - Percentage of CPU utilization at the system level.
  			%iowait - Percentage of time that the CPU or CPUs were idle 
  				during which the system had an outstanding disk I/O request.
  
  usage: $MYNAME -ds -c <critical value> -w <warning value> 
	
	-c <interger>
		This is the precentage with out % sign.  E.G. 95 would 
		represent 95% CPU Utilized.  Default value is 95.
		Exit with a critical status if less than the 
		percent of CPU idle.
	-w <interger>
		This is the precentage with out % sign.  E.G. 95 would 
		represent 95% CPU Utilized.  Default value is 85.
		Exit with a warning status if less than the 
		percent of CPU idle.
	-C <interger>
		This sets the number of the sample of data to collect.  
		The result is the average of the collected sample.  
		The default is 5.
	-d Debug
	
EOF
  print ("UNKOWN: $DISPLAY_STATUS\n");
  exit($STATUS_UNKNWN);
}


&Get_CPU_Status();
&Return_Status();

sub Get_CPU_Status
{
 foreach (`$SAR $SARINT $SARCOUNT`) {
   Debug (" LINE > $_ ");
   $tmpstrg = $_;
 
   if ($tmpstrg =~ /^Average/) {
 	
 	Debug ("MATCHED 1 > $tmpstrg");
 	($type, $CPU, $USER, $NICE, $SYSTEM, $IOWAIT, $STEAL, $IDLE) = (split /\s+/, $tmpstrg);
 	Debug ("$type, $CPU, $USER, $NICE, $SYSTEM, $IOWAIT, $STEAL, $IDLE");
 	next;
   }
 }
 
 ##Calculate CPU Used
 $CPU_USED = 100 - $IDLE;
 $CPU_USED = sprintf"%.2f",$CPU_USED;
 
 $DISPLAY_STATUS = "CPU_USED=$CPU_USED\%;$WARNING;$CRITICAL;; USER=$USER\%;$WARNING;$CRITICAL;; SYSTEM=$SYSTEM\%;$WARNING;$CRITICAL;; IOWAIT=$IOWAIT\%;$WARNING;$CRITICAL;; ";
 &Nagios_Status($CPU_USED,$USER,$SYSTEM,$IOWAIT);
}


sub Nagios_Status {
	my $CPU_USED = shift;
	my $USER = shift;
	my $SYSTEM = shift;
	my $IOWAIT = shift;
	
	##Nagios Status
  if ($CRITICAL < $CPU_USED) {
	  $STATUS = "CRITICAL";
	  $PROB_STATUS = "$PROB_STATUS CPU_USED=$CPU_USED$UNIT;USER:$USER$UNIT;SYSTEM:$SYSTEM$UNIT;IOWait:$IOWAIT$UNIT";
	} elsif ($WARNING < $CPU_USED) {
		if ($STATUS eq "CRITICAL") {
			
			$PROB_STATUS = "$PROB_STATUS CPU_USED=$CPU_USED$UNIT;USER:$USER$UNIT;SYSTEM:$SYSTEM$UNIT;IOWait:$IOWAIT$UNIT";
				
		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {
			
			$STATUS = "WARNING";
			$PROB_STATUS = "$PROB_STATUS CPU_USED=$CPU_USED$UNIT;USER:$USER$UNIT;SYSTEM:$SYSTEM$UNIT;IOWait:$IOWAIT$UNIT";
				
		}
	} else {
		if(($STATUS eq "UNKNOWN") || ($STATUS eq "OK")) {
			$STATUS = "OK";
		}
	}
	&Debug("$STATUS $DISPLAY_STATUS");
	&Debug("$STATUS PROB LIST > $PROB_STATUS");
}

sub Return_Status {
  if ($STATUS eq "CRITICAL") {
		print ("$STATUS $PROB_STATUS|$DISPLAY_STATUS\n");
     	exit($STATUS_CRIT);
  	}elsif ($STATUS eq "WARNING") {	
     	print ("$STATUS $PROB_STATUS|$DISPLAY_STATUS\n");
     	exit($STATUS_WARN);
  	}elsif ($STATUS eq "OK") {
     	print ("OK|$DISPLAY_STATUS\n");
     	exit($STATUS_OK);
  	}else {
     	print ("UNKNOWN|$DISPLAY_STATUS\n");
     	exit($STATUS_UNKNOWN);
  	}
  
}
 

sub Debug
{
  my ($msg) = @_;
  warn "$msg\n" if ($DEBUG);
}

