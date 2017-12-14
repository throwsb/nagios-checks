#!/usr/bin/perl

###################
# check script to check for Network statistics
#  usage on linux.  The base is
#  using the sar command
#
# The script is maintained at https://github.com/throwsb/nagios-checks/
#
# Licensed under GNU GPLv3 - see the LICENSE file in the git repository.
#
#  Created by David Worth 17-Apr-2017
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
$COMPOPR;
$SWAP=$FALSE;
$DISPLAY_STATUS;
$PROB_STATUS;

$SAR="/usr/bin/sar";
$SARDEV=" -n DEV";
$SAREDEV=" -n EDEV";
$SARSOCK=" -n SOCK";
$SARCMD="";
$SARRUN="";
$SARINT=10;
$SARCOUNT=1;
#$SAROPTS=" 1 15";
$TPS=0;
$RREQTPS=0;
$WREQTPS=0;
$BLKREADS=0;
$BLKWRTNS=0;
$UNIT="KB";


getopts('dhlbesc:w:i:W:') or Usage();
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
if($opt_b) {
	$SARCMD = "$SAR $SARDEV $SARINT $SARCOUNT";
	$SARRUN="bandwidth";
}
if($opt_e) {
	$SARCMD = "$SAR $SAREDEV $SARINT $SARCOUNT";
	$SARRUN="nic_error";
}
if($opt_s) {
	$SARCMD = "$SAR $SARSOCK $SARINT $SARCOUNT";
	$SARRUN="socket";
}
if($opt_h) {
	$COMPOPR = 'LT' ;
}elsif($opt_l) {
	$COMPOPR = 'GT';
}else{
	print("\n Error, missing comparison flag.  Use -h or -l \n");
	Usage();
}

if($COMPOPR eq "LT"){
	if ($WARNING >= $CRITICAL) {
  	print ("\n Warning is greater than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  	Usage();
	}
}elsif ($COMPOPR eq "GT"){
	if ($WARNING <= $CRITICAL) {
  	print ("\n Warning is less than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  	Usage();
	}
}else {
	print("\n Error with warning and critical thresholds: W:$WARNING C:$CRITICAL\n");
	Usage;
}

sub Usage {

  warn <<EOF;

  $MYNAME - Checks the Network statistics.  The following options are available.
	usage: $MYNAME -blhds -c <critical value> -w <warning value>

  -b Network device bandwidth
    Alerts can be used against rxKBsec and txKBsec.  Data is collected for each
    network interface except for localhost (l0). You will be required to pass
    the warning and critical values.  The choice is also available to set alerting
    against the high (-h) or low (-l) range.  An example of low would be alerting if received
    or transfer bandwidth is below a certain threshold.  An example of high would
    be alerting if received or transfer bandwidth exceeds a certain threshold.

    Details on metrics collected are as follows.

     rxKBsec - Total number of kilobytes received per second.
     txKBsec - Total number of kilobytes transmitted per second.
     rxPCKsec - Total number of packets received per second.
     txPCKsec - Total number of packets transmitted per second.

    Example call

    Call with thresholds on high values:
    $MYNAME -b -h -w 100 -c 200

  -e Network device failures or errors
    Data is collected for each network interface except for localhost (l0). You
    will be required to pass the warning and critical values.  The choice is also
    available to set alerting against the high (-h) or low (-l) range.  An
    example of low would be alerting if errors are below a certain threshold.
    An example of high would be alerting if errors exceeds a certain threshold.

    Details on metrics collected are as follows.  All will report alerts.

    rx_errorsec - Total number of bad packets received per second.
    tx-errorsec - Total number of bad packets received per second.
    coll_sec - Total number of bad packets received per second.
    rx_dropsec - Number  of  received  packets dropped per second because of
          a lack of space in linux buffers.
    tx_dropsec - Number of transmitted packets dropped per second because of
          a lack of space in linux buffers.

    Example call

    Call with thresholds on high values:
    $MYNAME -e -h -w 10 -c 20

  -s Network TCP established socket count.
    Data is collected for TCP sockets currently in use by the system. You
    will be required to pass the warning and critical values.  The choice is also
    available to set alerting against the high (-h) or low (-l) range.  An
    example of low would be alerting if errors are below a certain threshold.
    An example of high would be alerting if errors exceeds a certain threshold.

    Details on metrics collected are as follows.  All will report alerts.

    TCP_Active_Sockets - Number of TCP sockets currently in use.

    Example call

    Call with thresholds on high values:
    $MYNAME -s -h -w 100 -c 200

	-c <interger>
		Sets the critical threshold value.  This will depend if checking for high
		limit (-h) or low limit (-l).
	-w <interger>
		Sets the warning threshold value.  This will depend if checking for high
		limit (-h) or low limit (-l).
	-i <interger>
		This sets the interval for a single data run to collect.
		The result is the average of the collected sample.
		The default is 10.
	-h Set threshold checking to high limit.
	-l Set threshold checking to low limit.
	-d Debug

EOF
  print ("UNKOWN: $DISPLAY_STATUS\n");
  exit($STATUS_UNKNWN);
}

if($SARRUN eq "bandwidth"){
	Debug("Run is Bandwidth and sar cmd is $SARCMD");
	&Get_Net_Dev_Status();
}elsif($SARRUN eq "nic_error"){
		Debug("Run is Errors and sar cmd is $SARCMD");
		&Get_Dev_Error_Status();
}elsif($SARRUN eq "socket"){
		Debug("Run is Socket and sar cmd is $SARCMD");
		&Get_TCP_SOCKET_Status();

}else {
	print("Run type is not specified");
	Usage();
}

&Return_Status();

sub Get_Net_Dev_Status
{
 foreach (`$SARCMD`) {
   Debug (" LINE > $_ ");
   $tmpstrg = $_;

	 if ($tmpstrg =~ /IFACE/) {
		 next;
	 }
	 if ($tmpstrg =~ /lo/) {
		 next;
	 }

   if ($tmpstrg =~ /^Average/) {

 		Debug ("MATCHED 1 > $tmpstrg");
 		($type, $IF, $RXPCKS, $TXPCKS, $RXKBS, $TXKBS, $RST) = (split /\s+/, $tmpstrg);
 		Debug ("$type, $IF, $RXPCKS, $TXPCKS, $RXKBS, $TXKBS, $RST");

		$CurrentStatus{$IF}{rxpcks} = $RXPCKS;
		$CurrentStatus{$IF}{txpcks} = $TXPCKS;
		$CurrentStatus{$IF}{rxkbs} = $RXKBS;
		$CurrentStatus{$IF}{txkbs} = $TXKBS;
 		next;
   }
 }

  foreach my $nic (sort keys %CurrentStatus) {
		my $problem,$outvar;
		my $outdesc, $outmetric;

		$rxkbs = $CurrentStatus{$nic}{rxkbs};
		$txkbs = $CurrentStatus{$nic}{txkbs};
		$rxpcks = $CurrentStatus{$nic}{rxpcks};
		$txpcks = $CurrentStatus{$nic}{txpcks};

		Debug("NIC: $nic rxKBsec:$rxkbs txKBsec:$txkbs rxpcksec:$rxpcks txpcksec:$txpcks");
		$DISPLAY_STATUS ="$DISPLAY_STATUS $nic:rxKBsec=$rxkbs$UNIT;$WARNING;$CRITICAL;; $nic:txKBsec=$txkbs$UNIT;$WARNING;$CRITICAL;; $nic:rxPCKsec=$rxpcks;;;; $nic:txPCKsec=$txpcks;;;;";

		Debug("DS: $DISPLAY_STATUS");

		for ("rxKBsec:$rxkbs", "txKBsec:$txkbs") {
			($problem, $outvar) = Nagios_Status($_);
			Debug("IN for > PROB:$problem, outvar:$outvar, DESC:$outdesc, MET:$outmetric\n");
			if ($problem eq "ALERT"){
				($outdesc, $outmetric) = (split /:/, $outvar);
				$PROB_STATUS = "$PROB_STATUS $nic:$outdesc=$outmetric$UNIT";
				Debug("In Alert > outvar:$outvar, DESC:$outdesc, MET:$outmetric\n");

			}
		}

		&Debug("$STATUS $DISPLAY_STATUS");
		&Debug("$STATUS PROB LIST > $PROB_STATUS");

	}
}

sub Get_Dev_Error_Status
{
 foreach (`$SARCMD`) {
   Debug (" LINE > $_ ");
   $tmpstrg = $_;

	 if ($tmpstrg =~ /IFACE/) {
		 next;
	 }
	 if ($tmpstrg =~ /lo/) {
		 next;
	 }

   if ($tmpstrg =~ /^Average/) {

 		Debug ("MATCHED 1 > $tmpstrg");
 		($type, $IF, $RXERRS, $TXERRS, $COLLS, $RXDROPS, $TXDROPS, $RST) = (split /\s+/, $tmpstrg);
 		Debug ("$type, $IF, $RXERRS, $TXERRS, $COLLS, $RXDROPS, $TXDROPS, $RST");

		$CurrentStatus{$IF}{rxerrs} = $RXERRS;
		$CurrentStatus{$IF}{txerrs} = $TXERRS;
		$CurrentStatus{$IF}{colls} = $COLLS;
		$CurrentStatus{$IF}{rxdrops} = $RXDROPS;
		$CurrentStatus{$IF}{txdrops} = $TXDROPS;
 		next;
   }
 }

  foreach my $nic (sort keys %CurrentStatus) {
		my $problem,$outvar;
		my $outdesc, $outmetric;

		$rxerrs = $CurrentStatus{$nic}{rxerrs};
		$txerrs = $CurrentStatus{$nic}{txerrs};
		$colls  = $CurrentStatus{$nic}{colls};
		$rxdrops = $CurrentStatus{$nic}{rxdrops};
		$txdrops = $CurrentStatus{$nic}{txdrops};

		Debug("NIC: $nic rxerrsec:$rxerrs txerrsec:$txerrs collisions:$colls rxdropsec:$rxdrops txdropsec:$txdrops");
		$DISPLAY_STATUS ="$DISPLAY_STATUS $nic:rx_errorsec=$rxerrs;$WARNING;$CRITICAL;; $nic:tx-errorsec=$txerrs;$WARNING;$CRITICAL;; $nic:coll_sec=$colls;$WARNING;$CRITICAL;; $nic:rx_dropsec=$rxdrops;$WARNING;$CRITICAL;; $nic:tx_dropsec=$txdrops;$WARNING;$CRITICAL;;";

		Debug("DS: $DISPLAY_STATUS");

		for ("rx_errorsec:$rxerrs", "tx-errorsec:$txerrs", "coll_sec=$colls") {
			($problem, $outvar) = Nagios_Status($_);
			Debug("IN for > PROB:$problem, outvar:$outvar, DESC:$outdesc, MET:$outmetric\n");
			if ($problem eq "ALERT"){
				($outdesc, $outmetric) = (split /:/, $outvar);
				$PROB_STATUS = "$PROB_STATUS $nic:$outdesc=$outmetric$UNIT";
				Debug("In Alert > outvar:$outvar, DESC:$outdesc, MET:$outmetric\n");

			}
		}

		&Debug("$STATUS $DISPLAY_STATUS");
		&Debug("$STATUS PROB LIST > $PROB_STATUS");

	}
}

sub Get_TCP_SOCKET_Status{
	my $problem;
	foreach (`$SARCMD`) {
    Debug (" LINE > $_ ");
    $tmpstrg = $_;

    if ($tmpstrg =~ /^Average/) {

  		Debug ("MATCHED 1 > $tmpstrg");
  		($type, $TOTSCK, $TCPSCK, $RST) = (split /\s+/, $tmpstrg);
  		Debug ("$type, $TOTSCK, $TCPSCK, $RST");
  		next;
    }
  }
	$DISPLAY_STATUS = "TCP_Active_Sockets=$TCPSCK;$WARNING;$CRITICAL;;";
	($problem) = Nagios_Status($TCPSCK);
	if ($problem eq "ALERT"){
		$PROB_STATUS = "$PROB_STATUS TCP_Active_Sockets=$TCPSCK";
	}
	&Debug("$STATUS $DISPLAY_STATUS");
	&Debug("$STATUS PROB LIST > $PROB_STATUS");
}

sub Nagios_Status {
	my $invar = shift;
	my $problem ="OK";
	my $DETAIL = $FALSE;

	if ($invar =~ /:/) {
		($desc,$metric) = (split /:/, $invar);
		Debug("Nag Status > invar:$invar, DESC:$desc, MET:$metric\n");
		$DETAIL = $TRUE;
	}else {
		$metric = $invar;
	}
  if ($COMPOPR eq "LT"){
		 $cond = sub { $_[0] < $metric};
	}elsif ($COMPOPR eq "GT") {
		 $cond = sub { $_[0] > $metric};
	}

	##Nagios Status
  if ($cond ->($CRITICAL)) {
	  $STATUS = "CRITICAL";
		$problem = "ALERT";

	} elsif ($cond ->($WARNING)) {
		if ($STATUS eq "CRITICAL") {
			$problem = "ALERT";
		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {
			$STATUS = "WARNING";
			$problem = "ALERT";
		}
	} else {
		if(($STATUS eq "UNKNOWN") || ($STATUS eq "OK")) {
			$STATUS = "OK";
		}
	}
	if ($DETAIL) {
		return($problem, $invar);
	}else {
		return ($problem);
	}

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
