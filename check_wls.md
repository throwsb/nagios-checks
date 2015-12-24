##check_wls.pl##

###usage: **check_wls.pl** -dhjortT -x <Port:ManagedServerName,...> ###
  		-s <Server Name or IP> -W <path to WLST>
  		-J <path to jmx.py file>
  		-U <path to userConfigFile>
  		-K <path to userKeyFile>
  		-c <critical value> -w <warning value> 
  		
  		**check_wls.pl** -dhjortT -x <Port:ManagedServerName,...> 
  		-s <Server Name or IP> -W <path to WLST>
  		-J <path to jmx.py file>
  		-u <user name>
  		-p <password>
  		-c <critical value> -w <warning value> 
  		
  		**check_wls.pl** -dhjortT -l
  		-c <critical value> -w <warning value>
  		
  		**check_wls.pl** -dhjortT
  		-L <Path to Port:ManagedServer Config>
  		-c <critical value> -w <warning value>
	
	###SERVER Connection Details:###
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
		
	###Available CHECKS:###
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
		
	###ALERT Threshold Details:###
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