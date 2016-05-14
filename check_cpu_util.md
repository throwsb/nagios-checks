##check_cpu_util.pl

#### **check_cpu_util.pl** - Checks the CPU utilization across all CPU's on a server and returns the percentage used.  It will also provide the following statistics:
```		
  	%CPU - Total percentage of CPU utilization.
  	%user - Percentage of CPU utilization at the user level.
  	%system - Percentage of CPU utilization at the system level.
  	%iowait - Percentage of time that the CPU or CPUs were idle 
		  during which the system had an outstanding disk I/O request.
```

#### Usage: 
```
	check_cpu_util.pl -ds -c <critical value> -w <warning value> 
	
	-c <interger>
		This is the precentage with out % sign.  E.G. 95 would 
		represent 95% CPU Utilized.  Default value is 95.
		Exit with a critical status if less than the 
		percent of CPU idle.
	-w <interger>
		This is the precentage with out % sign.  E.G. 95 would 
		represent 95% CPU Utilized.  Default value is 85.
		Exit with a warning status if less than the 
		percent of CPU idle.
	-C <interger>
		This sets the number of the sample of data to collect.  
		The result is the average of the collected sample.  
		The default is 5.
	-d Debug

```

#### Installation and Configuration

##### File location and requirements

* check_cpu_util.pl - Default location is /usr/local/nagios/libexec.
	* Other location NAGIOS_HOME/libexec
	
* Linux sar command.
	
##### Nagios configuration examples

**Command Example**
	
Command Name | Command Line
------------ | --------------
check_nrpe_cpu-util | $USER1$/check_nrpe -H $HOSTADDRESS$ -t 60 -c check_cpu-util -a "$ARG1$"
	
	
Service Configuration Example 1 - Check CPU Utilization
	
Check | Command Name | Argument
----- | ------------ | --------------	
CPU Util | check_nrpe_cpu-util | -w 85 -c 95
	
	
**NRPE Client Configuration**

Add to the nrpe common.cfg
```
	### CPU Utilization ###
	command[check_cpu-util]=/usr/local/nagios/libexec/check_cpu_util.pl $ARG1$
```	
	
[Nagios Checks Home](http://throwsb.github.io/nagios-checks/)
