#!/usr/bin/perl

###################
# check script to check for Disk IO
#  usage on linux.  The base is
#  using the sar command
#
# The script is maintained at https://github.com/throwsb/nagios-checks/
#
# Licensed under GNU GPLv3 - see the LICENSE file in the git repository.
#
#  Created by David Worth 20-Feb-2017
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
$CRITICAL = "2000";
$WARNING = "1000";
$SWAP=$FALSE;
$DISPLAY_STATUS;
$PROB_STATUS;

$SAR="/usr/bin/sar -b";
$SARINT=15;
$SARCOUNT=1;
#$SAROPTS=" 1 15";
$TPS=0;
$RREQTPS=0;
$WREQTPS=0;
$BLKREADS=0;
$BLKWRTNS=0;

$UNIT="%";


getopts('dc:w:i:W:') or Usage();
$DEBUG = $TRUE if ($opt_d);
if($opt_w) {
	$WARNING = $opt_w;
	$WARNING =~ m/^[0-9]+$/ or (print "\nERROR: WARNING is not an unsigned digit: $WARNING \n" and  Usage());
}
if($opt_c) {
	$CRITICAL = $opt_c;
	$CRITICAL =~ m/^[0-9]+$/ or (print "\nERROR: CRITICAL is not an unsigned digit: $CRITICAL \n" and  Usage());
}
if($opt_i) {
	$SARINT = $opt_i;
	$SARINT =~ m/^[0-9]+$/ or (print "\nERROR: Count is not an unsigned digit: $SARCOUNT \n" and  Usage());
}


if ($WARNING >= $CRITICAL) {
  print ("\n Warning is less than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  Usage();
}


sub Usage {

  warn <<EOF;

  $MYNAME - Checks the disk I/O and transfer rate.  It will also
			provide the following statistics:

  			tps - Total number of transfers per second that were issued to physical devices.
  			rtps - Total number of read requests per second issued to physical devices.
  			wtps - Total number of write requests per second issued to physical devices.
  			blkreas/s - Total amount of data read from the devices in blocks per second.
  			blkwrtn/s - Total amount of data written to devices in blocks per second.

  usage: $MYNAME -ds -c <critical value> -w <warning value>

	-c <interger>
		Default value is 2000.
		Exit with a critical status if less than average tps.
	-w <interger>
		Default value is 1000.
		Exit with a warning status if less than average tps.
	-i <interger>
		This sets the interval for a single data run to collect.
		The result is the average of the collected sample.
		The default is 15.
	-d Debug

EOF
  print ("UNKOWN: $DISPLAY_STATUS\n");
  exit($STATUS_UNKNWN);
}


&Get_DISKIO_Status();
&Return_Status();

sub Get_DISKIO_Status
{
 foreach (`$SAR $SARINT $SARCOUNT`) {
   Debug (" LINE > $_ ");
   $tmpstrg = $_;

   if ($tmpstrg =~ /^Average/) {

 	Debug ("MATCHED 1 > $tmpstrg");
 	($type, $TPS, $RREQTPS, $WREQTPS, $BLKREADS, $BLKWRTNS) = (split /\s+/, $tmpstrg);
 	Debug ("$type, $TPS, $RREQTPS, $WREQTPS, $BLKREADS, $BLKWRTNS");
 	next;
   }
 }


 $DISPLAY_STATUS = "Trans_Per_Sec=$TPS;$WARNING;$CRITICAL;; Read_Req_Per_Sec=$RREQTPS;;;; Write_Req_Per_Sec=$WREQTPS;;;; BLK_Read_Per_Sec=$BLKREADS;;;; BLK_Write_Per_Sec=$BLKWRTNS;;;;";
 &Nagios_Status($TPS,$RREQTPS,$WREQTPS,$BLKREADS,BLKWRTNS);
}


sub Nagios_Status {
	my $TPS = shift;
	my $RREQTPS = shift;
	my $WREQTPS = shift;
	my $BLKREADS = shift;
	my $BLKWRTNS = shift;

	##Nagios Status
  if ($CRITICAL < $TPS) {
	  $STATUS = "CRITICAL";
	  $PROB_STATUS = "$PROB_STATUS Trans_Per_Sec=$TPS;Read_Req_Per_Sec=$RREQTPS;Write_Req_Per_Sec=$WREQTPS;BLK_Read_Per_Sec=$BLKREADS;BLK_Write_Per_Sec=$BLKREADS";

	} elsif ($WARNING < $TPS) {
		if ($STATUS eq "CRITICAL") {

			$PROB_STATUS = "$PROB_STATUS Trans_Per_Sec=$TPS;Read_Req_Per_Sec=$RREQTPS;Write_Req_Per_Sec=$WREQTPS;BLK_Read_Per_Sec=$BLKREADS;BLK_Write_Per_Sec=$BLKREADS";

		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {

			$STATUS = "WARNING";
			$PROB_STATUS = "$PROB_STATUS Trans_Per_Sec=$TPS;Read_Req_Per_Sec=$RREQTPS;Write_Req_Per_Sec=$WREQTPS;BLK_Read_Per_Sec=$BLKREADS;BLK_Write_Per_Sec=$BLKREADS";

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
