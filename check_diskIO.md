##check_diskIO.pl

#### **check_diskIO.pl** - Checks the disk I/O and transfer rate.  It will also provide the following statistics:
```		
  	tps - Total number of transfers per second that were issued to physical devices.
  	rtps - Total number of read requests per second issued to physical devices.
  	wtps - Total number of write requests per second issued to physical devices.
  	blkreas/s - Total amount of data read from the devices in blocks per second.
  	blkwrtn/s - Total amount of data written to devices in blocks per second.
```

#### Usage: 
```
	usage: check_diskIO.pl -ds -c <critical value> -w <warning value>

	-c <interger>
		Default value is 2000.
		Exit with a critical status if less than average tps.
	-w <interger>
		Default value is 1000.
		Exit with a warning status if less than average tps.
	-i <interger>
		This sets the interval for a single data run to collect.
		The result is the average of the collected sample.
		The default is 15.
	-d Debug

```

#### Installation and Configuration

##### File location and requirements

* check_diskIO.pl - Default location is /usr/local/nagios/libexec.
	* Other location NAGIOS_HOME/libexec
	
* Linux sar command.
	
##### Nagios configuration examples

**Command Example**
	
Command Name | Command Line
------------ | --------------
check_nrpe_diskIO | $USER1$/check_nrpe -H $HOSTADDRESS$ -t 60 -c check_diskIO -a "$ARG1$"
	
	
Service Configuration Example 1 - Check CPU Utilization
	
Check | Command Name | Argument
----- | ------------ | --------------	
diskIO | check_nrpe_diskIO | 
	
	
**NRPE Client Configuration**

Add to the nrpe common.cfg
```
	### CPU Utilization ###
	command[check_diskIO]=/usr/local/nagios/libexec/check_diskIO.pl $ARG1$
```	
	
[Nagios Checks Home](http://throwsb.github.io/nagios/)
