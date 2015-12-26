#!/usr/bin/perl

###################
# check script to monitor memory usage on a HP-UX server.
#  
# The script is maintained at https://github.com/throwsb/nagios-checks/
#
# Licensed under GNU GPLv3 - see the LICENSE file in the git repository.
#
###################


use POSIX;
use Getopt::Std;
use Sys::Hostname;

$TRUE = 1;
$FALSE = 0;
$STATUS_OK=0;
$STATUS_WARN=1;
$STATUS_CRIT=2;
$STATUS_UNKNWN=3;
($MYNAME = $0) =~ s/.*\///;
($HOST) = split /\./, hostname();
$DEBUG=$FALSE;
$STATUS = "UNKNOWN";
$CRITICAL = 90;
$WARNING = 80;

$SWALK = "/usr/bin/snmpwalk -Oq -v2c";
$HPUXOIDMemTot = ".1.3.6.1.4.1.11.2.3.1.1.8";
$HPUXOIDMemFree = ".1.3.6.1.4.1.11.2.3.1.1.7";
$MemTot = "0";
$MemFree = "0";
$MemUsed = "100"; ##Setting used to 100% for default value##
$SNMPCOM = "";
$HOST = "";
$tmp = "";

getopts('dc:w:C:h:') or Usage();
$DEBUG = $TRUE if ($opt_d);
$CRITICAL = $opt_c if ($opt_c);
$WARNING = $opt_w if ($opt_w);
$SNMPCOM = $opt_C if ($opt_C);
$HOST = $opt_h if ($opt_h);

if ($WARNING >= $CRITICAL) {
  print ("\n Warning is greater than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  Usage();
}elsif ($SNMPCOM eq "") {
  print ("\nEnter the SNMP community name:\n");
  Usage();
}elsif ($HOST eq "" ) {
  print ("\nEnter the Host name:\n");
  Usage();
}

sub Usage {

  warn <<EOF;
  
  $MYNAME - Checks the memory usage on a HP-UX server with a SNMP query.  
  
  usage: $MYNAME -c <critical value> -w <warning value> -C <SNMP Community Name> -h <host>
	
	-c <interger>
		Exit with a critical status if greater than the percent of free memory.
	-w <interger>
		Exit with a warning status if greater than the percent of free memory.
	-C <SNMP Community name>
		The snmp comunity name used by the server.  e.g. public
	-h <hostname>
		The hostname of the server that is being queried.

EOF
  print ("UNKNOWN: TOT:$MemTot FREE:$MemFree USED:$MemUsed\%\n");
  exit($STATUS_UNKNWN);
}

GetSnmp ();
CalcMem ();
NagiosStatus ();

sub GetSnmp {
 Debug("$SWALK -c $SNMPCOM $HOST $HPUXOIDMemTot");
 ($tmp,$MemTot) = split(/ /,`$SWALK -c $SNMPCOM $HOST $HPUXOIDMemTot`);
 chomp($MemTot);
 Debug("$SWALK -c $SNMPCOM $HOST $HPUXOIDMemFree");
 ($tmp,$MemFree) = split(/ /,`$SWALK -c $SNMPCOM $HOST $HPUXOIDMemFree`);
 chomp($MemFree);

 Debug("$HOST > TOT:$MemTot, FREE:$MemFree ");

}

sub CalcMem {
  $MemUsed = ceil((($MemTot - $MemFree)*100)/$MemTot);
  Debug("TOT:$MemTot FREE:$MemFree USED:$MemUsed\%");

}

sub NagiosStatus {
  if ($CRITICAL < $MemUsed) {
    print ("CRITICAL: TOT:$MemTot FREE:$MemFree USED:$MemUsed\%\n");
    exit($STATUS_CRIT);
  }elsif ($WARNING < $MemUsed) {
    print ("WARNING: TOT:$MemTot FREE:$MemFree USED:$MemUsed\%\n");
    exit($STATUS_WARN);
  }else {
    print ("OK: TOT:$MemTot FREE:$MemFree USED:$MemUsed\%\n");
    exit($STATUS_OK);
  }
}
 

sub Debug
{
  my ($msg) = @_;
  warn "$msg\n" if ($DEBUG);
}

