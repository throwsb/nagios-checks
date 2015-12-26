##check_memoryfree.pl

#### **check_memoryfree.pl** - Checks the memory and swap usage on a Linux server using the free command.  

#### Usage: 
```
	check_memoryfree.pl -ds -c <critical value> -w <warning value> 
	
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
```

#### Installation and Configuration

##### File location and requirements

* check_memoryfree.pl - Default location is /usr/local/nagios/libexec.  
	* Other location NAGIOS_HOME/libexec
	
* Linux free command.
	
##### Nagios configuration examples

**Command Example**
	
Command Name | Command Line
------------ | --------------
check_nrpe_memoryfree | $USER1$/check_nrpe -H $HOSTADDRESS$ -t 60 -c check_memfree -a "$ARG1$"
	
	
Service Configuration Example 1 - Check Memory Utilization
	
Check | Command Name | Argument
----- | ------------ | --------------	
Memory Util | check_nrpe_memoryfree | -w 90 -c 95 -s
	
	
**NRPE Client Configuration**

Add to the nrpe common.cfg
```
	### Memory Utilization ###
	command[check_memfree]=/usr/local/nagios/libexec/check_memoryfree.pl $ARG1$
```

##check_memory-linux.pl

#### **check_memory-linux.pl** - Checks the memory usage on a Linux server with a SNMP query.  

#### Usage: 
```
	check_memory-linux.pl -c <critical value> -w <warning value> 
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

* check_memory-linux.pl - Default location is /usr/local/nagios/libexec on the Nagios XI or Core server.  
	* Other location NAGIOS_HOME/libexec
	* This check is executed from the Nagios server.
	
* Linux free command.
	
##### Nagios configuration examples

**Command Example**
	
Service Configuration Example 1 - Check Memory Linux
	
Check | Command Name | Arg1 | Arg2 | Arg3
----- | ------------ | ---- | ---- | ----	
Check Memory Linux | check-linux-snmp-memory | SNMP Community Name | Warn | Crit
	
	
[Nagios Checks Home](http://throwsb.github.io/nagios-checks/)