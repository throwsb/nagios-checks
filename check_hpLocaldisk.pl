#!/usr/bin/perl

###################
# check script to check for a failed local disk
#  on a rack mount server that uses hardware raid
#  controller. Connections are made to the array
#  controller using HP Array Configuration Utility CLI,
#  /usr/sbin/hpacucli.
#  
# The script is maintained at https://github.com/throwsb/nagios-checks/
#
# Licensed under GNU GPLv3 - see the LICENSE file in the git repository.
#
#
#  Created by David Worth 24-Jul-2013
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
$STATUS = "OK";
$CRITICAL = "Failed";
##$WARNING = "Recovering";
$REBUILD = "Rebuilding";
$PREDFAIL = "Predictive";
$ACTIVE = "active";
$OK = "OK";
##$DISPLAY_STATUS ="$HOST Local Disk Status:";
$DISPLAY_STATUS;
$PROB_STATUS;

$HPACUCLI = "/usr/sbin/hpacucli";
$HPSSACLI = "/usr/sbin/hpssacli";
$ARRAYCMD = "";
$ARRAYOPTS = "ctrl all show config";

getopts('dh:') or Usage();
##getopts('dc:w:') or Usage();
$DEBUG = $TRUE if ($opt_d);
##$CRITICAL = $opt_c if ($opt_c);
##$WARNING = $opt_w if ($opt_w);
if ($opt_h) {
  Usage ();
}


sub Usage {

  warn <<EOF;
  usage: $MYNAME -dh 

    -d Print debug information.
    -h Print help information.

  $MYNAME is a check script to monitor local disk status on HP servers.
    It connects to the local disk controller using hpacucli or hpssacli 
    and pulls the status of the disks.  The status and corresponding
    alerts can be any of the following:

	UNKNOWN - The status is either unknown or unrecognized.  
		This generates a Warning alert.
		
	OK	- The disks are in an OK status.  No alert.
	
	Predictive - The disks are reporting a predictive failure.
		The reported disk should be updated.  This 
		generates a Warning alert.
		
	Rebuilding - The disk is currently re-syncing with the 
		raid set.  This is usually the case after a 
		disk was replaced.  This generates a Warning
		alert.
		
	Failed 	- One of the disks in the raid set has failed.
		This generates a Critical alert.

EOF
  print ("UNKOWN: $DISPLAY_STATUS\n");
  exit($STATUS_UNKNWN);
}

##Set array controller

if (-f -X $HPACUCLI) {
  $ARRAYCMD = $HPACUCLI;
  Debug ("ARRAY > $ARRAYCMD OPTS > $ARRAYOPTS");
}elsif (-f -X $HPSSACLI) {
   $ARRAYCMD = $HPSSACLI;
  Debug ("ARRAY > $ARRAYCMD OPTS > $ARRAYOPTS");
} else {
  print (" \n No Valid Array Controller Command Found\n");
  Usage ();
}

Get_Disk_Status();
Check_Disk_Data();

sub Get_Disk_Status
{
 foreach (`$ARRAYCMD $ARRAYOPTS`) {
   Debug (" LINE > $_ ");
   $tmpstrg = $_;
 
   if ($tmpstrg =~ /^\s+logicaldrive/) {
 	$tmpstrg =~ s/^\s+//;
 	Debug ("MATCHED 1 > $tmpstrg");
 	#($drive, $dnum, $v1, $v2, $v3, $v4, $status) = split / /, $tmpstrg;
 	($drive, $dnum, $v1, $v2, $v3, $v4, @status) = split / /, $tmpstrg;
 	##Format data
 	$drive = "$drive:$dnum";
	$status = "@status";
 	$status =~ s/\)//;
 	Debug ("DRIVE $drive STATUS - @status");
 	$DRVSTATUS{$drive}=$status; 
 	next;
   }elsif ($tmpstrg =~ /^\s+physicaldrive/) {
 	$tmpstrg =~ s/^\s+//;
 	Debug ("MATCHED 2 > $tmpstrg");
 	@physdrive = split / /, $tmpstrg;
 	##Format data
 	$status = $physdrive[-1];
 	Debug ("Status Preif > $status");
 	if ($status =~ /^spare/) {
 		$status = $physdrive[-2];
 	}
 	$status =~ s/\)//;
	$status =~ s/\,//;
	Debug ("STATUS Postif > $status");
 	$drive = "$physdrive[0]:$physdrive[1]";
 	Debug ("DRIVE $drive STATUS $status");
 	$DRVSTATUS{$drive}=$status; 
 	next;
   }
 }
}

sub Check_Disk_Data
{
	Debug("=========START CHECK=========");
  while (($key,$value) = each %DRVSTATUS) {
    ##chomp ($value);
    $DISKDRV = $key;
    $DSKSTATUS = $value;
    chomp ($DSKSTATUS);
    Debug ("CHECK -> $DISKDRV - $DSKSTATUS");
    $DISPLAY_STATUS = "$DISPLAY_STATUS $DISKDRV=$DSKSTATUS";
    Debug ("DS > $DISPLAY_STATUS\n");

    if ($key =~ /^physicaldrive/) {
	  Debug ("SETTING STATUS -> STATUS VAL -> $value");
	  
	  if ($DSKSTATUS eq "UNKNOWN") {
	  	if(($STATUS eq "WARNING") || ($STATUS eq $CRITICAL)) {
	  		$PROB_STATUS = "$PROB_STATUS $DISKDRV:$DSKSTATUS";
	  	}elsif(($STATUS eq "UNKNOWN") || ($STATUS eq "OK")){
	  		$STATUS = "UNKNOWN";
	  		$PROB_STATUS = "$PROB_STATUS $DISKDRV:$DSKSTATUS";
	  	}
	  }elsif($DSKSTATUS eq $CRITICAL) {
	  	if(($STATUS eq "CRITICAL") || ($STATUS eq "WARNING") || ($STATUS eq "OK") || ($STATUS eq "UNKNOWN")) {
	  		$STATUS = "CRITICAL";
	  		$PROB_STATUS = "$PROB_STATUS $DISKDRV:$DSKSTATUS";
	  	}
	  }elsif(($DSKSTATUS eq $REBUILD) || ($DSKSTATUS eq $PREDFAIL) || ($DSKSTATUS eq $ACTIVE)){
	  	if ($STATUS eq "CRITICAL") {
	  		$PROB_STATUS = "$PROB_STATUS $DISKDRV:$DSKSTATUS";
	  	}elsif(($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {
			$STATUS = "WARNING";
			$PROB_STATUS = "$PROB_STATUS $DISKDRV:$DSKSTATUS";		
		}	
	  }
    }
    &Debug("$STATUS $DISPLAY_STATUS");
	&Debug("$STATUS PROB LIST > $PROB_STATUS");
  }
 
  ###Check Status
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
     print ("UNKNOWN $PROB_STATUS|$DISPLAY_STATUS\n");
     exit($STATUS_UNKNOWN);
  }

}

 

sub Debug
{
  my ($msg) = @_;
  warn "$msg\n" if ($DEBUG);
}

