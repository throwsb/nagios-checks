#!/usr/bin/perl

###################
# check script to monitor CPU usage on a HP-UX server.
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
$CRITICAL = 15;
$WARNING = 20;

$SAR = "/usr/bin/sar 1 5";

getopts('dc:w:') or Usage();
$DEBUG = $TRUE if ($opt_d);
$CRITICAL = $opt_c if ($opt_c);
$WARNING = $opt_w if ($opt_w);

if ($WARNING <= $CRITICAL) {
  Usage();
}

sub Usage {

  warn <<EOF;
  
  $MYNAME - Checks the CPU usage on a HP-UX.
  
  usage: $MYNAME -c <critical value> -w <warning value>
  
  	-c <interger>
		Exit with a critical status if greater than the total CPU idle.  The
		critical value can not be higher than the warning status.
	-w <interger>
		Exit with a warning status if greater than the total CPU idle.  The
		warning value can not be lower than the critical value.

EOF
  print ("UNKOWN: CPU $AVG: \%USER:$USR \%SYSTEM:$SYS \%IOWAIT:$WIO \%IDLE:$IDL\n");
  exit($STATUS_UNKNWN);
}

foreach (`$SAR`) {
  ($AVG,$USR,$SYS,$WIO,$IDL) = split(/\s+/,$_);
  Debug("av > $AVG, usr > $USR,sys > $SYS,io > $WIO,idle > $IDL");
}

if ($AVG ne "Average") {
  print ("UNKOWN: CPU $AVG: \%USER:$USR \%SYSTEM:$SYS \%IOWAIT:$WIO \%IDLE:$IDL\n");
  exit($STATUS_UNKNWN);
} else {
  if ($CRITICAL > $IDL) {
    print ("CRITICAL: CPU $AVG: \%USER:$USR \%SYSTEM:$SYS \%IOWAIT:$WIO \%IDLE:$IDL\n");
    exit($STATUS_CRIT);
  }elsif ($WARNING > $IDL) {
    print ("WARNING: CPU $AVG: \%USER:$USR \%SYSTEM:$SYS \%IOWAIT:$WIO \%IDLE:$IDL\n");
    exit($STATUS_WARN);
  }else {
    print ("OK: CPU $AVG: \%USER:$USR \%SYSTEM:$SYS \%IOWAIT:$WIO \%IDLE:$IDL\n");
    exit($STATUS_OK);
  }
}

 

sub Debug
{
  my ($msg) = @_;
  warn "$msg\n" if ($DEBUG);
}

