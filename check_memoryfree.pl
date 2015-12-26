#!/usr/bin/perl

###################
# check script to check for memory
#  usage on linux.  The base is 
#  using the free command
#
# The script is maintained at https://github.com/throwsb/nagios-checks/
#
# Licensed under GNU GPLv3 - see the LICENSE file in the git repository.
#
#  Created by David Worth 3-Apr-2015
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
$CRITICAL = "90";
$WARNING = "80";
$SWAP=$FALSE;
$DISPLAY_STATUS;
$PROB_STATUS;

$FREE="/usr/bin/free";
$FREEOPTS="-m";
$MemTot=0;
$MemTotGB=0;
$MemFree=0;
$MemFreeGB=0;
$MemUsedPerc=0;
$MemUsed=0;
$MemUsedGB=0;
$MemType="";
$SwapTot=0;
$SwapTotGB=0;
$SwapFree=0;
$SwapFreeGB=0;
$SwapUsed=0;
$SwapUsedGB=0;
$SwapUsedPerc=0;
$UNIT="GB";


getopts('dsc:w:') or Usage();
$DEBUG = $TRUE if ($opt_d);
$CRITICAL = $opt_c if ($opt_c);
$WARNING = $opt_w if ($opt_w);
if ($opt_s) {
	$SWAP=$TRUE;
}

if ($WARNING >= $CRITICAL) {
  print ("\n Warning is greater than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  Usage();
}


sub Usage {

  warn <<EOF;
  
  $MYNAME - Checks the memory and swap usage on a Linux server using the free command.
  
  usage: $MYNAME -ds -c <critical value> -w <warning value> 
	
	-s	Check SWAP space too.
	-c <interger>
		This is the precentage with out % sign.  E.G. 95 would 
		represent 95% utilized.  Default value is 95.
		Exit with a critical status if greater than the 
		percent of free memory.
	-w <interger>
		This is the precentage with out % sign.  E.G. 95 would 
		represent 95% utilized.  Default value is 90.
		Exit with a warning status if greater than the 
		percent of free memory.
	-d Debug
	
EOF
  print ("UNKOWN: $DISPLAY_STATUS\n");
  exit($STATUS_UNKNWN);
}


&Get_Memory_Status();
&CalcMem();
&Return_Status();

sub Get_Memory_Status
{
 foreach (`$FREE $FREEOPTS`) {
   Debug (" LINE > $_ ");
   $tmpstrg = $_;
 
   if ($tmpstrg =~ /^Mem/) {
 	
 	Debug ("MATCHED 1 > $tmpstrg");
 	($mem, $MemTot, @junk) = (split /\s+/, $tmpstrg);
 	Debug ("MEM > $mem TotMem > $MemTot");
 	next;
   }elsif ($tmpstrg =~ /^\-\/\+/) {
 	
 	Debug ("MATCHED 2 > $tmpstrg");
 	($buff, $MemUsed, $MemFree) = (split /\s+ /, $tmpstrg);
 	Debug ("Used > $MemUsed  Free  > $MemFree");
 	next;
   }elsif ($tmpstrg =~ /^Swap/) {
	 Debug ("MATCHED 3 > $tmpstrg");
 	 ($swap, $SwapTot, $SwapUsed, $SwapFree) = (split /\s+ /, $tmpstrg);
 	 Debug ("STot > $SwapTot; SUsed > $SwapUsed; SFree > $SwapFree ");
 	 next;
	}
 }
}

sub CalcMem {
  ##Physical Memory
  $MemType="Physical";
  ##$MemUsedPerc = ceil((($MemTot - $MemFree)*100)/$MemTot);
  $MemUsedPerc = ceil(($MemUsed*100)/$MemTot);
  Debug("perc > $MemUsedPerc\%");
  
  ##Convert to GB
  $MemTotGB = ($MemTot/1024);
  $MemTotGB = sprintf"%.2f",$MemTotGB;
  $MemFreeGB = ($MemFree/1024);
  $MemFreeGB = sprintf"%.2f",$MemFreeGB;
  $MemUsedGB = ($MemUsed/1024);
  $MemUsedGB = sprintf"%.2f",$MemUsedGB;
  Debug("MemTotGB:$MemTotGB$UNIT, MemFreeGB:$MemFreeGB$UNIT, TOT:$MemTot FREE:$MemFree USED:$MemUsedGB$UNIT PercUsed:$MemUsedPerc\%");
  $DISPLAY_STATUS = "$MemType=$MemUsedPerc\%;$WARNING;$CRITICAL;;";
  Debug("DISPLAY > $DISPLAY_STATUS");
  ##Call NAgios Status to determine health
  &Nagios_Status($MemType,$MemUsedPerc,$MemTotGB,$MemFreeGB,$MemUsedGB);
  
  if ($SWAP) {
	##Swap Space
	$MemType="SWAP";
  
	$SwapUsedPerc = ceil(($SwapUsed*100)/$SwapTot);
	Debug("perc > $SwapUsedPerc\%");
  
	##Convert to GB
	$SwapTotGB = ($SwapTot/1024);
	$SwapTotGB = sprintf"%.2f",$SwapTotGB;
	$SwapFreeGB = ($SwapFree/1024);
	$SwapFreeGB = sprintf"%.2f",$SwapFreeGB;
	$SwapUsedGB = ($SwapUsed/1024);
	$SwapUsedGB = sprintf"%.2f",$SwapUsedGB;
	Debug("SwapTotGB:$SwapTotGB$UNIT, SwapFreeGB:$SwapFreeGB$UNIT, TOT:$SwapTot FREE:$SwapFree USED:$SwapUsedGB$UNIT PercUsed:$SwapUsedPerc\%");
	$DISPLAY_STATUS = "$DISPLAY_STATUS $MemType=$SwapUsedPerc\%;$WARNING;$CRITICAL;;";
	Debug("DISPLAY > $DISPLAY_STATUS");
	##Call NAgios Status to determine health
	&Nagios_Status($MemType,$SwapUsedPerc,$SwapTotGB,$SwapFreeGB,$SwapUsedGB);
  }
}

sub Nagios_Status {
	my $MemType = shift;
	my $PercUsed = shift;
	my $TotMem = shift;
	my $FreeMem = shift;
	my $UsedMem = shift;
	
	##Nagios Status
  if ($CRITICAL < $PercUsed) {
	  $STATUS = "CRITICAL";
	  $PROB_STATUS = "$PROB_STATUS $MemType=$PercUsed\%;Tot:$TotMem$UNIT;Free:$FreeMem$UNIT;Used:$UsedMem$UNIT";
	} elsif ($WARNING < $PercUsed) {
		if ($STATUS eq "CRITICAL") {
			
			$PROB_STATUS = "$PROB_STATUS $MemType=$PercUsed\%;Tot:$TotMem$UNIT;Free:$FreeMem$UNIT;Used:$UsedMem$UNIT";
				
		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {
			
			$STATUS = "WARNING";
			$PROB_STATUS = "$PROB_STATUS $MemType=$PercUsed\%;Tot:$TotMem$UNIT;Free:$FreeMem$UNIT;Used:$UsedMem$UNIT";
				
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

