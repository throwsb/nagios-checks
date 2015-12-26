#!/usr/bin/perl

###################
# check script to check for quota usage on en EMC
#  Isilon.  This is an active check and is executed
#  on the Isilon.  
#  controller using HP Array Configuration Utility CLI,
#  /usr/sbin/hpacucli.
#  
# The script is maintained at https://github.com/throwsb/nagios-checks/
#
# Licensed under GNU GPLv3 - see the LICENSE file in the git repository.
#
#  Created by David Worth 30-May-2014
#  version 0.1
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
$CRITICAL = 95;
$WARNING = 90;
$MATCH_PATH;
$DISPLAY_STATUS;
$PROB_STATUS;
$DFSU="MB";
$FSU="m";
$QUOTACMD = "/usr/bin/isi quota ls --format csv -a";

getopts('dgc:p:w:') or Usage();
$DEBUG = $TRUE if ($opt_d);
$CRITICAL = $opt_c if ($opt_c);
$WARNING = $opt_w if ($opt_w);
$MATCH_PATH = $opt_p if ($opt_p);
if ($opt_g) {
	$FSU = "g";
	$DFSU = "GB";
}

&Debug("CRITICAL:$CRITICAL WARNING:$WARNING FSU:$FSU DFSU:$DFSU ");

if ($WARNING >= $CRITICAL) {
  print ("\n Warning is greater than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  Usage();
}

sub Usage {

  warn <<EOF;
  
  $MYNAME - Checks the disk quotas usage on a EMC Isilon cluster.  
  
  usage: $MYNAME -dg -c <critical value> -w <warning value> -p <path or regex>
	
	-p <string>
	    Restrict check to a specific path or regex. 
	-c <interger>
		This is the precentage with out % sign.  E.G. 95 would 
		represent 95% utilized.  Default value is 95.
		Exit with a critical status if greater than the 
		percent of free disk space.
	-w <interger>
		This is the precentage with out % sign.  E.G. 95 would 
		represent 95% utilized.  Default value is 90.
		Exit with a warning status if greater than the 
		percent of free disk space.
	-g Display Filesystem in GB.  The default is MB.
	-d Debug

EOF
  print ("UNKNOWN:\n");
  exit($STATUS_UNKNWN);
}



&Get_Quota_Status();
&Check_Quota_Data();
&Return_Status();

sub Get_Quota_Status
{
	&Debug("CMD > $QUOTACMD");
	foreach (`$QUOTACMD`) {
		##&Debug("Line > $_ ");
		$tmpstrg = $_;
		
		($type,$appl,$path,$snap,$hard,$soft,$adv,$used) = split /,/, $tmpstrg;
		
		##Calc percentage
		if($hard == 0)
		{
			next;
		} else {
			$percused = ceil(($used/$hard)*100);
		}
		
		##Convert to Mb
		##$hard = (($hard/1024)/1024);
		($hard) = Convert_FS_Units($hard);
		##$used = (($used/1024)/1024);
		($used) = Convert_FS_Units($used);
		
		&Debug("Path:$path,Tot:$hard,Used:$used,Percent:$percused");
		
		if ($MATCH_PATH) {
			if ($path =~ /$MATCH_PATH/) {
			  $QUOTASTATUS{$path}{hard} = $hard;
		      $QUOTASTATUS{$path}{used} = $used;
		      $QUOTASTATUS{$path}{perc} = $percused;
		    }
		} else {		
		   $QUOTASTATUS{$path}{hard} = $hard;
		   $QUOTASTATUS{$path}{used} = $used;
		   $QUOTASTATUS{$path}{perc} = $percused;
		}
		
		next;
	}


}

sub Convert_FS_Units
{
	my ($tmpfs) = @_;
	##&Debug(" FSU > $tmpfs");
	
	if($FSU eq "g") {
		$tmpfs = ((($tmpfs/1024)/1024)/1024);
	}else {
		$tmpfs = (($tmpfs/1024)/1024);
	}
	
	return $tmpfs;
}
		
sub Check_Quota_Data
{
	foreach my $path (sort keys %QUOTASTATUS) {
		##foreach my $usage (keys %{ $QUOTASTATUS{$path} }){
			
		##	&Debug("$path, $usage: $QUOTASTATUS{$path}{$usage}");
		
		$FS = "$path";
		$PERCUSED = $QUOTASTATUS{$path}{perc};
		$TOT = $QUOTASTATUS{$path}{hard};
		$USED = $QUOTASTATUS{$path}{used};
		
		&Debug("$path=$PERCUSED\%;$TOT$DFSU;$USED$DFSU");
		
		$DISPLAY_STATUS = "$DISPLAY_STATUS '$path'=$PERCUSED\%;$WARNING;$CRITICAL;;";
		##$DISPLAY_STATUS = "$DISPLAY_STATUS $path=$PERCUSED\%;$TOT$DFSU;$USED$DFSU";
		#}
		
		##Nagios Status
		if($CRITICAL < $PERCUSED) {
			if (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "CRITICAL") || ($STATUS eq "OK")) {
			
				$STATUS = "CRITICAL";
				$PROB_STATUS = "$PROB_STATUS $path=$PERCUSED\%;$TOT$DFSU;$USED$DFSU ";
				
			}
		} elsif ($WARNING < $PERCUSED) {
			if ($STATUS eq "CRITICAL") {
			
				$PROB_STATUS = "$PROB_STATUS $path=$PERCUSED\%;$TOT$DFSU;$USED$DFSU ";
				
			} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {
			
				$STATUS = "WARNING";
				$PROB_STATUS = "$PROB_STATUS $path=$PERCUSED\%;$TOT$DFSU;$USED$DFSU ";
				
			}
		} else {
			if(($STATUS eq "UNKNOWN") || ($STATUS eq "OK")) {
				$STATUS = "OK";
			}
		}
	}
	
	&Debug("$STATUS $DISPLAY_STATUS");
	&Debug("$STATUS PROB LIST > $PROB_STATUS");
	
}

sub Return_Status
{

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
