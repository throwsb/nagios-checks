##check_memory-isilon.pl

#### **check_memory-isilon.pl** - Checks the memory usage on a EMC Isilon Node with a SNMP query.  

#### Usage: 
```
	check_memory-isilon.pl -c <critical value> -w <warning value> 
						   -C <SNMP Community Name> -h <host>
	
	-c <interger>
		Exit with a critical status if greater than the percent of free memory.
	-w <interger>
		Exit with a warning status if greater than the percent of free memory.
	-C <SNMP Community name>
		The snmp comunity name used by the server.  e.g. public
	-h <hostname>
		The hostname of the server that is being queried.

		
```

#### Installation and Configuration

##### File location and requirements

* check_memory-isilon.pl - Default location is /usr/local/nagios/libexec on the Nagios XI or Core server.  
	* Other location NAGIOS_HOME/libexec
	* This check runs from the Nagios server by using a SNMP query.
	
* Install the Isilon SNMP Mibs into Nagios.  They can be downloaded from your OneFS Web.
	* Navigate to Cluster Management > General Settings > SNMP Monitoring
	
* Isilon Cluster Configuration
	* Create a local nagios user/group on the Isilon Cluster.
	* Create the home dir for the nagios user in /ifs/nagios.
	* Copy the plugin to /ifs/nagios.
	
##### Nagios configuration examples

**Command Example**
	
Command Name | Command Line
------------ | --------------
check-isilon-snmp-memory | $USER1$/check_memory-isilon.pl -h $HOSTADDRESS$ -C $ARG1$ -w $ARG2$ -c $ARG3$
	
	
Service Configuration Example 1 - Check Memory Isilon
	
Check | Command Name | Arg1 | Arg2 | Arg3
----- | ------------ | ---- | ---- | ----	
Check Memory Isilon | check-isilon-snmp-memory | SNMP Community Name | Warn | Crit

Run this check against all Isilon nodes.
	


##isilon_quota_check.pl

#### **isilon_quota_check.pl** - Checks the disk quotas usage on a EMC Isilon cluster.  

#### Usage: 
```
	isilon_quota_check.pl -dg -c <critical value> -w <warning value> -p <path or regex>
	
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

```

#### Installation and Configuration

##### File location and requirements

* isilon_quota_check.pl - Default location is /ifs/nagios on the Isilon Cluster.  
	
* Install the Isilon SNMP Mibs into Nagios.  They can be downloaded from with in the OneFS Web.
	* Navigate to Cluster Management > General Settings > SNMP Monitoring
	
* Isilon Cluster Configuration
	* Create a local nagios user/group on the Isilon Cluster.
	* Create the home dir for the nagios user in /ifs/nagios.
	* Copy the plugin to /ifs/nagios.
	* *chown nagiosuser:nagios* of check script.
	* *chmod 750* of check script.
	
	
##### Nagios configuration examples

**Command Example**
	
Command Name | Command Line
------------ | --------------
check_remote_isilon | $USER1$/check_by_ssh -t 90 -l nagiosis -H $HOSTADDRESS$ -C "$ARG1$ -g $ARG2$"
	
	
Service Configuration Example 1 - Check Isilon Quota ssh
	
Check | Command Name | Arg1 | Arg2
----- | ------------ | ---- | -----	
Isilon Quota | check_remote_isilon | /usr/bin/perl isilon_quota_check.pl | -w 90 -c 95


Service Configuration Example 2 - Check Isilon specific Quota
	
Check | Command Name | Arg1 | Arg2
----- | ------------ | ---- | -----	
Isilon Quota | check_remote_isilon | /usr/bin/perl isilon_quota_check.pl | -p 'sql\|ora' -w 85 -c 95



[Nagios Checks Home](http://throwsb.github.io/nagios-checks/)