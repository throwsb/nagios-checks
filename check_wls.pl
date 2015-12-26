#!/usr/bin/perl

###################
# check script to check health
#  of a Weblogic Managed Server.  
#  This calls wlst and uses a 
#	jmx interface.
#
# The script is maintained at https://github.com/throwsb/nagios-checks/
#
# Licensed under GNU GPLv3 - see the LICENSE file in the git repository.
#
#  Created by David Worth 11-May-2015
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
$CRITICAL = "";
$WARNING = "";
$SWAP=$FALSE;
$DISPLAY_STATUS;
$PROB_STATUS;

$WLST="";
$JMX="/usr/local/nagios/libexec/jmx.py";
$USRCFG="";
$USRKEY="";
$USRKEYFLAG=$FALSE;
$USR="";
$PASSWD="";
$USRPWFLAG=$FALSE;
$JMXUSR="";
$JMXPW="";
$AUTHTYPE="";
$CHECK="";
$SERVLST="";
$CFGFILE="/usr/local/nagios/etc/wls_config";
$CFGFLAG=$FALSE;
$HOST="";
$MGSERVER="";
@HEALTHCRIT=("HEALTH_CRITICAL","HEALTH_FAILED");
@HEALTHWARN=("HEALTH_WARN","HEALTH_OVERLOADED","LOW_MEMORY_REASON");



##getopts('dc:w:x:p:s:m:') or Usage();
getopts('dc:hjortTCw:x:lL:s:W:J:U:K:u:p:') or Usage();
$DEBUG = $TRUE if ($opt_d);
$CRITICAL = $opt_c if ($opt_c);
$WARNING = $opt_w if ($opt_w);
if($opt_l) {
	##Using default file location
	if ( (-e $CFGFILE) && (-f $CFGFILE)){
		$CFGFLAG = $TRUE;
	} else {
		print("\n Warning: Config File is missing ");
		Usage();
	}
}elsif($opt_L) {
	$CFGFILE = $opt_L;
	if ( (-e $CFGFILE) && (-f $CFGFILE)){
		$CFGFLAG = $TRUE;
	} else {
		print("\n Warning: Config File is missing ");
		Usage();
	}
}else {
	if($opt_x) {
		$SERVLST = $opt_x;
	}else{
		print("\n Warning: port:ManagedServerName not set.  Use -x, -l or -L ");
		Usage();
	}
	if($opt_s){
		$HOST = $opt_s;
	}else {
		print("\n Warning: Server Name or IP set with only one flag, -s, -l, or -L ");
		Usage();
	}
	if($opt_J){
		if (( -e $opt_J) && (-f $opt_J)) {
			$JMX = $opt_J;
		}else {
			print("\n Warning: missing jmx.py $opt_J ");
			Usage();
		}	
	}elsif($JMX eq "") {
		print("\n Warning: missing path to jmx.py ");
		Usage();
	}elsif(( !-e $JMX) && (!-f $JMX)) {
		print("\n Warning: missing path to jmx.py $JMX  ");
		Usage();
	}
	if($opt_W) {
		if (( -e $opt_W) && (-f $opt_W)) {
			$WLST = $opt_W;
		}else {
			print("\n Warning: missing wlst ");
			Usage();
		}	
	}elsif($WLST eq "") {
		print("\n Warning: missing path to wlst ");
		Usage();
	}
	if(($opt_U) && ($opt_K)){
		if ((-e $opt_U) && (-f $opt_U)){
			$USRCFG = $opt_U;
			$USRKEYFLAG=$TRUE;
			$AUTHTYPE="KEY";
		}else {
			print("Warning: Connection User Config File is missing ");
			$USRKEYFLAG=$FALSE;
			Usage();
		}
		if ($USRKEYFLAG) {
			if ((-e $opt_K) && (-f $opt_K)){
				$USRKEY = $opt_K;
				$AUTHTYPE="KEY";
			}else {
				print("Warning: Connection User Key File is missing ");
				$USRKEYFLAG=$FALSE;
				Usage();
			}
		}
	}elsif(($opt_u) && ($opt_p)){
		$USR = $opt_u;
		$PASSWD = $opt_p;
		if(($USR eq "") || ($PASSWD eq "")) {
			print("Warning: Connection Credentials are missing ");
			Usage();
		}else {
			$USRPWFLAG=$TRUE;
			$AUTHTYPE="USRPW";
		}
	}else {
		print("Warning: Connection Credentials are missing ");
		Usage();
	}
}

if($opt_h){
	$CHECK = "HeapFreePercent";
}elsif($opt_r){
	$CHECK = "HealthState";
}elsif($opt_o){
	$CHECK = "OverallHealthState";
}elsif($opt_t){
	$CHECK = "ThreadHealthState";
}elsif($opt_T){
	$CHECK = "StuckThreadCount";
}elsif($opt_j){
	$CHECK = "JDBCHealthState";
}elsif($opt_C){
	$CHECK = "ThreadTotCount";
}else{
	print("\n Warning: missing Server Check...");
	Usage();
}



sub Usage {

  warn <<EOF;
  
  $MYNAME Checks the health of a Weblogic instance using jmx and wlst.
  
  usage: $MYNAME -dhjortT -x <Port:ManagedServerName,...> 
  		-s <Server Name or IP> -W <path to WLST>
  		-J <path to jmx.py file>
  		-U <path to userConfigFile>
  		-K <path to userKeyFile>
  		-c <critical value> -w <warning value> 
  		
  		$MYNAME -dhjortT -x <Port:ManagedServerName,...> 
  		-s <Server Name or IP> -W <path to WLST>
  		-J <path to jmx.py file>
  		-u <user name>
  		-p <password>
  		-c <critical value> -w <warning value> 
  		
  		$MYNAME -dhjortT -l
  		-c <critical value> -w <warning value>
  		
  		$MYNAME -dhjortT
  		-L <Path to Port:ManagedServer Config>
  		-c <critical value> -w <warning value>
	
	SERVER Connection Details:
	-l	Pull a list of managed servers and ports from a 
		configuration file.  The default location is at
		/usr/local/nagios/etc/wls_config.  The location
		and file can be specified using the -L option.  
		
		The file contains a list of port and managed 
		server names, the hostname or IP the instances 
		are listening on, path to jmx.py, path to wlst and 
		connect credentials.  
		
		The Port/Managed Server name starts out with "srv::" 
		and each port and managed server is separated by a ":".  
		One grouping per line. The full format is as follows:
		srv::<port>:<instance name>
		
		The hostname or IP starts out with "hst::". The last 
		instance of "hst::<hostname or IP>" will be the 
		name used.  The full format is as follows:
		hst::<hostname or IP>
		
		The path to jmx.py starts out with "jmx::". The default
		is /usr/local/nagios/libexec/jmx.py.  The last 
		instance of "jmx::<path to jmx.py>" will be the one used.
		The format is as follows: jmx::</path/to/jmx.py>
		
		The path to wlst starts out with "wlst::". The last 
		instance of "wlst::<path to wlst>" will be the one used.
		The format is as follows: wlst::</path/to/wlst>
		
		The credentials used to connect to a managed server can 
		either be with a userConfigFile and userKeyFile or a 
		username and password.  You can only use one set.  To
		use a key file pair, the entry in the config file starts
		out with the following:
		"ucfg::<path to userConfigFile>"
		"ukey::<path to userKeyFile>"
		
		To use a username and password pair, the entry in the config
		file starts out with the following:
		"usr::<username>"
		"pwd"::<password>"
		
		Comments start out with "#".  See -L 
		or -x for details on other options to specify this 
		information.
		
		Here is an example of a config file:
		##Some comments
		hst::myhost
		jmx::/usr/local/nagios/libexec/jmx.py
		wlst::</path/to//wlst_sh>
		ucfg::</path/to/userConfigFile>
		ukey::</path/to/userKeyFile>
		srv::7210:wls10
		srv::7211:wls11
	
	-L	Pull a list of managed servers and ports from a 
		configuration file.  Enter the name and path to the 
		configuration file.  The default location is at
		/usr/local/nagios/etc/wls_config and is used with the 
		-l option.  
				
		The file contains a list of port and managed 
		server names, the hostname or IP the instances 
		is listening on, path to jmx.py, path to wlst and 
		connect credentials.   
		
		The Port/Managed Server name starts out with "srv::" 
		and each port and managed server is separated by a ":".  
		One grouping per line.  The full format is as follows:
		srv::<port>:<instance name>
		
		The hostname or IP starts out with "hst::". The last 
		instance of "hst::<hostname or IP>" will be the 
		name used.  The full format is as follows:
		hst::<hostname or IP>
		
		The path to jmx.py starts out with "jmx::". The default
		is /usr/local/nagios/libexec/jmx.py.  The last 
		instance of "jmx::<path to jmx.py>" will be the one used.
		The format is as follows: jmx::</path/to/jmx.py>
		
		The path to wlst starts out with "wlst::". The last 
		instance of "wlst::<path to wlst>" will be the one used.
		The format is as follows: wlst::</path/to/wlst>
		
		The credentials used to connect to a managed server can 
		either be with a userConfigFile and userKeyFile or a 
		username and password.  You can only use one set.  To
		use a key file pair, the entry in the config file starts
		out with the following:
		"ucfg::<path to userConfigFile>"
		"ukey::<path to userKeyFile>"
		
		To use a username and password pair, the entry in the config
		file starts out with the following:
		"usr::<username>"
		"pwd"::<password>"
		
		Comments start out with "#".  See -L 
		or -x for details on other options to specify this 
		information.
		
		Here is an example of a config file:
		##Some comments
		hst::myhost
		jmx::/usr/local/nagios/libexec/jmx.py
		wlst::/path/to/wlst_sh
		ucfg::</path/to/userConfigFile>
		ukey::</path/to/userKeyFile>
		srv::7210:wls10
		srv::7211:wls11
		
	-s	This is the server or IP name of where the managed 
		server is running on.  If the server name is 
		wlsserver.example.com, but the instance is listening 
		on a different name/IP, then you would use the other 
		name/IP.  E.G. wlsserverlistener.example.com.
		
	-J	<Path to jmx.py> Default is located in 
		/usr/local/nagios/libexec
		
	-W	<Path to WLST> 
		Enter the path to WLST.
		
	-x	This is a list of the managed server name and the 
		port it is listening on.  This can be a list of 
		multiple instances separated by a comma.  The PORT 
		and Managed Server is separated by a colon :.  This 
		list can also be added to a file.  See -l or -L for 
		more details.
		Here is an example of a list: 
		7210:wls10,7211:wls11,7212:wls12,...
		
	-U  This is used to set the path to the userConfigFile 
		in order to connect to a managed server.  This must 
		be used with the -K flag.  This can not be used with 
		the -u and -p flags.
		
	-K	This is used to set the path to the userKeyFile 
		in order to connect to a managed server.  This must 
		be used with the -U flag.  This can not be used with 
		the -u and -p flags.
		
	-u	This is used to set the username in order to connect
		to a managed server.  This must be used with the -p
		flag.  This can not be used with the -U and -K flags.
		
	-p	This is used to set the password in order to connect
		to a managed server.  This must be used with the -u
		flag.  This can not be used with the -U and -K flags.
		
	Available CHECKS:	
	-h	Check the Heap Free Percentage on a managed server.  
		Use this in conjunction with -c and -w for critical 
		and warning.  The lower the number, the less heap 
		is free.
		
	-j	JDBC Health State of a managed server.  -c and -w 
		are not used for this check.  Valid status checks 
		are as follows:
		Critical - HEALTH_CRITICAL, HEALTH_FAILED
		Warning	- HEALTH_WARN, HEALTH_OVERLOADED, LOW_MEMORY_REASON
		OK - Health_OK
		UNKNOWN - Status unavailable.
		
	-o	Overall Health State of a managed server.  -c and 
		-w are not used for this check.  Valid status checks 
		are as follows:
		Critical - HEALTH_CRITICAL, HEALTH_FAILED
		Warning	- HEALTH_WARN, HEALTH_OVERLOADED, LOW_MEMORY_REASON
		OK - Health_OK
		UNKNOWN - Status unavailable.
		
	-r	Health State of a managed server.  -c and -w are 
		not used for this check.  Valid status checks 
		are as follows:
		Critical - HEALTH_CRITICAL, HEALTH_FAILED
		Warning	- HEALTH_WARN, HEALTH_OVERLOADED, LOW_MEMORY_REASON
		OK - Health_OK
		UNKNOWN - Status unavailable.
		
	-t	Thread Health State of a managed server.  -c 
		and -w are not used for this check.  Valid 
		status checks are as follows:
		Critical - HEALTH_CRITICAL, HEALTH_FAILED
		Warning	- HEALTH_WARN, HEALTH_OVERLOADED, LOW_MEMORY_REASON
		OK - Health_OK
		UNKNOWN - Status unavailable.
		
	-T	Stuck Thread Count of a managed server.  Use this in 
		conjunction with -c and -w for critical and warning.  
		0 indicates no stucks threads.  A value greater than 0 
		indicates stuck threads.
		
	-C  Report the Thread Count Total on a managed server.  
		Use this in conjunction with -c and -w for critical 
		and warning.  An exit with a warning status occurs if the
		total exceeds the warning threshold and the warning is less 
		than critical.  An exit with a critical status occurs if the total
		exceeds the critical threshold.  The critical value must be greater 
		than the warning threshold.
		
	ALERT Threshold Details:
	-c <interger>
		If used with the -h option, exit with a CRITICAL status 
		if less than Heap Percent Free and less than the WARNING 
		status. 
		if used with the -T option, exit with a CRITICAL status
		if greater than the Stuck Thread Count and greater than the
		WARNING status.
		
	-w <interger>
		If used with the -h option, exit with a WARNING status 
		if less than Heap Percent Free and greater than the CRITICAL 
		status. 
		if used with the -T option, exit with a WARNING status
		if greater than the Stuck Thread Count and less than the
		CRITICAL status.
	
	-d Debug
	
EOF
  print ("UNKOWN: $DISPLAY_STATUS\n");
  exit($STATUS_UNKNOWN);
}

if ($CHECK eq "HeapFreePercent") {
  if ($WARNING <= $CRITICAL) {
  	print ("\n Warning is less than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  	Usage();
  }
	&Get_WL_HeapPerc();
	&Check_Heap_Data();
	&Return_Status();
}elsif ($CHECK eq "StuckThreadCount") {
  if ($WARNING >= $CRITICAL) {
  	print ("\n Warning is greater than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  	Usage();
  }
	&Get_WL_StuckThreads();
	&Check_Stuck_Threads_Data();
	&Return_Status();
}elsif ($CHECK eq "ThreadTotCount") {
  if ($WARNING >= $CRITICAL) {
  	print ("\n Warning is greater than or equal to Critical: W:$WARNING C:$CRITICAL\n");
  	Usage();
  }
	&Get_WL_ThreadCount();
	&Check_ThreadCount_Data();
	&Return_Status();
}elsif (($CHECK eq "HealthState")||($CHECK eq "OverallHealthState")||($CHECK eq "ThreadHealthState")||($CHECK eq "JDBCHealthState")) {
	&Get_WL_Health();
	&Check_Health_Data();
	&Return_Status();
}

sub Pull_Serv_Port_File
{
	open CFGFILE, '<', $CFGFILE or die "Cannot Open Port/Managed Server File $SRVLSTFILE $!";
	
	my @LIST = <CFGFILE>;
	close CFGFILE;
	
	foreach my $line ( @LIST )
	{
		Debug("Pull line > $line");
		if ($line =~ /^\#/) {
			##Comment, can ignore
			next;
		}elsif ($line =~ /^srv/) {
			($prtlst) = (split /::/, $line)[-1];
			chomp($prtlst);
			if($SERVLST eq "") {
				$SERVLST = $prtlst;
			}else {
				$SERVLST = "$SERVLST,$prtlst";
			}
			Debug ("Pull File Srvlst > $SERVLST");
			next;
		}elsif ($line =~ /^hst/) {
			($HOST) = (split /::/, $line)[-1];
			chomp($HOST);
		}elsif ($line =~ /^jmx/) {
			($JMX) = (split /::/, $line)[-1];
			chomp($JMX);
		}elsif ($line =~ /^wlst/) {
			($WLST) = (split /::/, $line)[-1];
			chomp($WLST);
		}elsif ($line =~ /^ucfg/) {
			($USRCFG) = (split /::/, $line)[-1];
			chomp($USRCFG);
			$USRKEYFLAG=$TRUE;
		}elsif ($line =~ /^ukey/) {
			($USRKEY) = (split /::/, $line)[-1];
			chomp($USRKEY);
			$USRKEYFLAG=$TRUE;
		}elsif ($line =~ /^usr/) {
			($USR) = (split /::/, $line)[-1];
			chomp($USR);
			$USRPWFLAG=$TRUE;
		}elsif ($line =~ /^pwd/) {
			($PASSWD) = (split /::/, $line)[-1];
			chomp($PASSWD);
			$USRPWFLAG=$TRUE;
		}
	}
	##Check port/mglist,host or ip, JMX, and WLST
	if($SERVLST eq "") {
		print("\n Warning: Port:ManagedServerName not set.  Use -x, -l or -L ");
		print("\n No valid Port:ManagedServerName in config file... ");
		Usage();
	}
	if($HOST eq "") {
		print("\n Warning: missing Server Name or IP. Use -s, -l, or -L ");
		print("\n No valid Server Name or IP in config file... ");
		Usage();
	}
	if ((!-e $JMX) && (!-f $JMX)) {
		print("\n Warning: missing jmx.py $JMX ");
		Usage();
	}elsif($JMX eq "") {
		print("\n Warning: missing path to jmx.py  ");
		print("\n No valid path in config file... ");
		Usage();
	}
	if((!-e $WLST) && (!-f $WLST)) {
		print("\n Warning: missing wlst $WLST ");
		Usage();
	}elsif($WLST eq "") {
		print("\n Warning: missing path to wlst ");
		print("\n No valid path in config file... ");
		Usage();
	}	
	##Credentials section
	if(($USRKEYFLAG) && ($USRPWFLAG)) {
		print("\n Warning: Passing in both Key and USR/Passwordd. ");
		print("\n Provide Key or USR/Password");
		Usage();
	}elsif ($USRKEYFLAG) {
		if(($USRCFG eq "") || ($USRKEY eq "")){
			print("\n Warning: missing Credential config or key file ");
			print("\n Config > $USRCFG amd Key > $USRKEY");
			$USRKEYFLAG=$FALSE;
			Usage();
		}elsif ((!-e $USRCFG) && (!-f $USRCFG)){
			print("Warning: Connection User Config File is missing ");
			$USRKEYFLAG=$FALSE;
			Usage();
		}elsif ((!-e $USRKEY) && (!-f $USRKEY)){
			print("Warning: Connection User Key File is missing ");
			$USRKEYFLAG=$FALSE;
			Usage();
		}else {
			$USRKEYFLAG=$TRUE;
			$AUTHTYPE="KEY";
		}
	}elsif ($USRPWFLAG) {
		if(($USR eq "") || ($PASSWD eq "")) {
			print("\n Warning: missing Credential user or password ");
			$USRPWFLAG=$FALSE;
			Usage();
		}else {
			$USRPWFLAG=$TRUE;
			$AUTHTYPE="USRPW";
		}
	}else {
		print("\n Warning: missing Credential in SRVLSTFILE ");
		Usage();
	}
}

sub Set_Credentials
{

	if($USRKEYFLAG) {
		$JMXUSR = ("$USRCFG");
		$JMXPW = ("$USRKEY");
	}elsif($USRPWFLAG) {
		$JMXUSR = ("$USR");
		$JMXPW = ("$PASSWD");
	}
}

sub Get_WL_ThreadCount
{
  if($CFGFLAG) {
  	&Pull_Serv_Port_File();
  }
  &Set_Credentials();
  
  @server = split /,/, $SERVLST;
  Debug ("SERV LIST > @server");
  foreach $item (@server) {
	
	($port,$mgserver) = split /:/, $item;
	Debug ("HOST > $HOST, PORT > $port, MGSERV > $mgserver, USR > $JMXUSR, PW > $JMXPW ATYPE > $AUTHTYPE");
	
	##Set Hash to unknown, allowing to get correct value if successful.
	$CurrentStatus{$mgserver}{threadcount} = "UNKNOWN";
	foreach (`$WLST $JMX $HOST $port $CHECK $mgserver $JMXUSR $JMXPW $AUTHTYPE`) {
   		Debug (" LINE > $_ ");
   		$tmpstrg = $_;
 
   		if ($tmpstrg =~ /^ThreadTotCount/) {
 	
 		  Debug ("MATCHED 1 > $tmpstrg");
 		  ($check, $threadtotcount) = (split /:/, $tmpstrg);
 		  Debug ("check > $check heap > $threadtotcount");
 		  chomp($threadtotcount);
 		  $CurrentStatus{$mgserver}{threadcount} = $threadtotcount;
 		  next;
    	}
  	}
  }

}

sub Check_ThreadCount_Data
{
	foreach my $mgserver (sort keys %CurrentStatus) {
	
	  $MGSERVER = "$mgserver";
	  $THREADTOTCOUNT = $CurrentStatus{$mgserver}{threadcount};
	
	  Debug("$MGSERVER:$THREADTOTCOUNT");
	  $DISPLAY_STATUS = "$DISPLAY_STATUS $MGSERVER=$THREADTOTCOUNT;$WARNING;$CRITICAL;;";
	
	  ##Nagios Status
	  if ($THREADTOTCOUNT eq "UNKNOWN") {
		if (($STATUS eq "WARNING") || ($STATUS eq "CRITICAL")) {
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$THREADTOTCOUNT;ThreadTotCount ";
		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "OK")) {
			$STATUS = "UNKNOWN";
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$THREADTOTCOUNT;ThreadTotCount ";
		} 
	  }elsif($CRITICAL < $THREADTOTCOUNT) {
		if (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "CRITICAL") || ($STATUS eq "OK")) {
			
			$STATUS = "CRITICAL";
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$THREADTOTCOUNT;ThreadTotCount ";
				
		}
	  } elsif ($WARNING < $THREADTOTCOUNT) {
		if ($STATUS eq "CRITICAL") {
			
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$THREADTOTCOUNT;ThreadTotCount ";
				
		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {
			
			$STATUS = "WARNING";
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$THREADTOTCOUNT;ThreadTotCount ";
				
		}
	  }  else {
		if ($STATUS eq "OK")  {
			$STATUS = "OK";
		}
	  }	
	}
	&Debug("$STATUS $DISPLAY_STATUS");
	&Debug("$STATUS PROB LIST > $PROB_STATUS");
	
}


sub Get_WL_StuckThreads
{
  if($CFGFLAG) {
  	&Pull_Serv_Port_File();
  }
  &Set_Credentials();
  
  @server = split /,/, $SERVLST;
  Debug ("SERV LIST > @server");
  foreach $item (@server) {
	
	($port,$mgserver) = split /:/, $item;
	Debug ("HOST > $HOST, PORT > $port, MGSERV > $mgserver, USR > $JMXUSR, PW > $JMXPW ATYPE > $AUTHTYPE");
	
	##Set Hash to unknown, allowing to get correct value if successful.
	$CurrentStatus{$mgserver}{stuckthreads} = "UNKNOWN";
	foreach (`$WLST $JMX $HOST $port $CHECK $mgserver $JMXUSR $JMXPW $AUTHTYPE`) {
   		Debug (" LINE > $_ ");
   		$tmpstrg = $_;
 
   		if ($tmpstrg =~ /^StuckThreadCount/) {
 	
 		  Debug ("MATCHED 1 > $tmpstrg");
 		  ($check, $stuckthreadcount) = (split /:/, $tmpstrg);
 		  Debug ("check > $check heap > $stuckthreadcount");
 		  chomp($stuckthreadcount);
 		  $CurrentStatus{$mgserver}{stuckthreads} = $stuckthreadcount;
 		  next;
    	}
  	}
  }

}

sub Check_Stuck_Threads_Data
{
	foreach my $mgserver (sort keys %CurrentStatus) {
	
	  $MGSERVER = "$mgserver";
	  $STUCKTHREADCOUNT = $CurrentStatus{$mgserver}{stuckthreads};
	
	  Debug("$MGSERVER:$HEAPFREE\%");
	  $DISPLAY_STATUS = "$DISPLAY_STATUS $MGSERVER=$STUCKTHREADCOUNT;$WARNING;$CRITICAL;;";
	
	  ##Nagios Status
	  if ($STUCKTHREADCOUNT eq "UNKNOWN") {
		if (($STATUS eq "WARNING") || ($STATUS eq "CRITICAL")) {
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STUCKTHREADCOUNT;StuckThreadCount ";
		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "OK")) {
			$STATUS = "UNKNOWN";
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STUCKTHREADCOUNT;StuckThreadCount ";
		} 
	  }elsif($CRITICAL < $STUCKTHREADCOUNT) {
		if (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "CRITICAL") || ($STATUS eq "OK")) {
			
			$STATUS = "CRITICAL";
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STUCKTHREADCOUNT;StuckThreadCount ";
				
		}
	  } elsif ($WARNING < $STUCKTHREADCOUNT) {
		if ($STATUS eq "CRITICAL") {
			
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STUCKTHREADCOUNT;StuckThreadCount ";
				
		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {
			
			$STATUS = "WARNING";
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STUCKTHREADCOUNT;StuckThreadCount ";
				
		}
	  }  else {
		if ($STATUS eq "OK")  {
			$STATUS = "OK";
		}
	  }	
	}
	&Debug("$STATUS $DISPLAY_STATUS");
	&Debug("$STATUS PROB LIST > $PROB_STATUS");
	
}


sub Get_WL_Health
{
  if($CFGFLAG) {
  	&Pull_Serv_Port_File();
  }
  
  &Set_Credentials();
  
  @server = split /,/, $SERVLST;
  Debug ("SERV LIST > @server");
  foreach $item (@server) {
	
	($port,$mgserver) = split /:/, $item;
	Debug ("HOST > $HOST, PORT > $port, MGSERV > $mgserver, USR > $JMXUSR, PW > $JMXPW, ATYPE > $AUTHTYPE");
	
	##Set Hash to unknown, allowing to get correct value if successful.
	$CurrentStatus{$mgserver}{state} = "UNKNOWN";
	foreach (`$WLST $JMX $HOST $port $CHECK $mgserver $JMXUSR $JMXPW $AUTHTYPE`) {
   		Debug (" LINE > $_ ");
   		$tmpstrg = $_;
 
   		##if ($tmpstrg =~ /^HealthState/) {
   		if ($tmpstrg =~ /^$CHECK/) {
 	
 		  Debug ("MATCHED 1 > $tmpstrg");
 		  ($type,$state,$mserver,$reason) = (split /,/, $tmpstrg);
 		  Debug ("type > $type state > $state server > $mserver reason> $reason");
 		  ($type) = (split /:/, $type)[-1];
 		  ($state) = (split /:/, $state)[-1];
 		  ($reason) = (split /:/, $reason)[-1];
 		  $CurrentStatus{$mgserver}{type} = $type;
 		  $CurrentStatus{$mgserver}{state} = $state;
 		  $CurrentStatus{$mgserver}{reason} = $reason;
 		  Debug ("CurState -> $CurrentStatus{$mgserver}{type}:$CurrentStatus{$mgserver}{state}:$CurrentStatus{$mgserver}{reason}");
 		  next;
    	}
  	}
  }
}

sub Check_Health_Data
{
	foreach my $mgserver (sort keys %CurrentStatus) {
	
	  $MGSERVER = "$mgserver";
	  $HLTHType = $CurrentStatus{$mgserver}{type};
	  $STATE = $CurrentStatus{$mgserver}{state};
	  $REASON = $CurrentStatus{$mgserver}{reason};
	
	  Debug("$MGSERVER:$STATE:$REASON");
	  $DISPLAY_STATUS = "$DISPLAY_STATUS $MGSERVER=$STATE;;;;";
	
	  ##Nagios Status
	  ##Critical State
	  
	  if ($STATE eq "UNKNOWN") {
			if (($STATUS eq "WARNING") || ($STATUS eq "CRITICAL")) {
				$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STATE;UNKNOWN DATA;$REASON ";
			} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "OK")) {
				$STATUS = "UNKNOWN";
				$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STATE;UNKNOWN DATA;$REASON ";
			}
		} elsif(($STATE eq "HEALTH_CRITICAL") || ($STATE eq "HEALTH_FAILED")) {
			if (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "CRITICAL") || ($STATUS eq "OK")) {
			
				$STATUS = "CRITICAL";
				$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STATE;$REASON ";
				
			}
		##Warning State	
		} elsif (($STATE eq "HEALTH_WARN") || ($STATE eq "HEALTH_OVERLOADED") || ($STATE eq "LOW_MEMORY_REASON")) {
			if ($STATUS eq "CRITICAL") {
			
				$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STATE;$REASON ";
				
			} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {
			
				$STATUS = "WARNING";
				$PROB_STATUS = "$PROB_STATUS $MGSERVER=$STATE;$REASON ";
				
			}		
		} else {
			if ($STATUS eq "OK") {
				$STATUS = "OK";
			}
		}	
	}
	&Debug("$STATUS $DISPLAY_STATUS");
	&Debug("$STATUS PROB LIST > $PROB_STATUS");	
}

sub Get_WL_HeapPerc
{
  if($CFGFLAG) {
  	&Pull_Serv_Port_File();
  }
  &Set_Credentials();
  
  @server = split /,/, $SERVLST;
  Debug ("SERV LIST > @server");
  foreach $item (@server) {
	
	($port,$mgserver) = split /:/, $item;
	Debug ("HOST > $HOST, PORT > $port, MGSERV > $mgserver, USR > $JMXUSR, PW > $JMXPW ATYPE > $AUTHTYPE");
	
	##Set Hash to unknown, allowing to get correct value if successful.
	$CurrentStatus{$mgserver}{heapfree} = "UNKNOWN";
	foreach (`$WLST $JMX $HOST $port $CHECK $mgserver $JMXUSR $JMXPW $AUTHTYPE`) {
   		Debug (" LINE > $_ ");
   		$tmpstrg = $_;
 
   		if ($tmpstrg =~ /^HeapFreePercent/) {
 	
 		  Debug ("MATCHED 1 > $tmpstrg");
 		  ($check, $heap) = (split /:/, $tmpstrg);
 		  Debug ("check > $check heap > $heap");
 		  chomp($heap);
 		  $CurrentStatus{$mgserver}{heapfree} = $heap;
 		  next;
    	}
  	}
  }

}

sub Check_Heap_Data
{
	foreach my $mgserver (sort keys %CurrentStatus) {
	
	  $MGSERVER = "$mgserver";
	  $HEAPFREE = $CurrentStatus{$mgserver}{heapfree};
	
	  Debug("$MGSERVER:$HEAPFREE\%");
	  $DISPLAY_STATUS = "$DISPLAY_STATUS $MGSERVER=$HEAPFREE\%;$WARNING;$CRITICAL;;";
	
	  ##Nagios Status
	  if ($HEAPFREE eq "UNKNOWN") {
		if (($STATUS eq "WARNING") || ($STATUS eq "CRITICAL")) {
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$HEAPFREE\%;HeapFreePercentage ";
		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "OK")) {
			$STATUS = "UNKNOWN";
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$HEAPFREE\%;HeapFreePercentage ";
		} 
	  }elsif($CRITICAL > $HEAPFREE) {
		if (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "CRITICAL") || ($STATUS eq "OK")) {
			
			$STATUS = "CRITICAL";
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$HEAPFREE\%;HeapFreePercentage ";
				
		}
	  } elsif ($WARNING > $HEAPFREE) {
		if ($STATUS eq "CRITICAL") {
			
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$HEAPFREE\%;HeapFreePercentage ";
				
		} elsif (($STATUS eq "UNKNOWN") || ($STATUS eq "WARNING") || ($STATUS eq "OK")) {
			
			$STATUS = "WARNING";
			$PROB_STATUS = "$PROB_STATUS $MGSERVER=$HEAPFREE\%;HeapFreePercentage ";
				
		}
	  }  else {
		if ($STATUS eq "OK")  {
			$STATUS = "OK";
		}
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
     	print ("UNKNOWN $PROB_STATUS|$DISPLAY_STATUS\n");
     	exit($STATUS_UNKNOWN);
  	}
  
}
 

sub Debug
{
  my ($msg) = @_;
  warn "$msg\n" if ($DEBUG);
}

