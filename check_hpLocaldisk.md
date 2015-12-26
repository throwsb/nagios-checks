##check_hpLocaldisk.pl

#### **check_hpLocaldisk.pl** - Checks the local disk status on HP servers by connecting to disk controller using hpacucli or hpssacli and pulls the current status .

#### Usage:
```
	check_hpLocaldisk.pl -dh 
    	-d Print debug information.
    	-h Print help information.
```

#### The status and corresponding alerts can be any of the following: 
```
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
```
#### Installation and Configuration

##### File location and requirements

* check_hpLocaldisk.pl - Default location is /usr/local/nagios/libexec.  
	* Other location NAGIOS_HOME/libexec
	
* Installation of HP hpacucli or hpssacli software.
	
##### Nagios configuration examples

**Command Example**
	
Command Name | Command Line
------------ | --------------
check_nrpe_hpLocaldisk | $USER1$/check_nrpe -H $HOSTADDRESS$ -t 60 -c check_hpLocaldisk
	
	
Service Configuration Example 1 - Check HP Disks
	
Check | Command Name | Argument
----- | ------------ | --------------	
Check HP Disks | check_nrpe_hpLocaldisk | none
	
	
**NRPE Client Configuration**

Add to the nrpe common.cfg
```
	### DISK ###
	command[check_hpLocaldisk]=/usr/bin/sudo /usr/local/nagios/libexec/check_hpLocaldisk.pl $ARG1$
```

[Nagios Checks Home](http://throwsb.github.io/nagios-checks/)