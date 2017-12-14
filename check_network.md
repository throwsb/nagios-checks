##check_network.pl

#### **check_network.pl** - Checks the Network statistics.  It will also provide the following statistics:
```		
    rxKBsec - Total number of kilobytes received per second.
    txKBsec - Total number of kilobytes transmitted per second.
    rxPCKsec - Total number of packets received per second.
    txPCKsec - Total number of packets transmitted per second.
```

#### Usage: 
```
	usage: check_network.pl -blhds -c <critical value> -w <warning value>

  -b Network device bandwidth
    Alerts can be used against rxKBsec and txKBsec.  Data is collected for each
    network interface except for localhost (l0). You will be required to pass
    the warning and critical values.  The choice is also available to set alerting
    against the high (-h) or low (-l) range.  An example of low would be alerting if received
    or transfer bandwidth is below a certain threshold.  An example of high would
    be alerting if received or transfer bandwidth exceeds a certain threshold.

    Details on metrics collected are as follows.

     rxKBsec - Total number of kilobytes received per second.
     txKBsec - Total number of kilobytes transmitted per second.
     rxPCKsec - Total number of packets received per second.
     txPCKsec - Total number of packets transmitted per second.

    Example call

    Call with thresholds on high values:
    check_network.pl -b -h -w 100 -c 200

  -e Network device failures or errors
    Data is collected for each network interface except for localhost (l0). You
    will be required to pass the warning and critical values.  The choice is also
    available to set alerting against the high (-h) or low (-l) range.  An
    example of low would be alerting if errors are below a certain threshold.
    An example of high would be alerting if errors exceeds a certain threshold.

    Details on metrics collected are as follows.  All will report alerts.

    rx_errorsec - Total number of bad packets received per second.
    tx-errorsec - Total number of bad packets received per second.
    coll_sec - Total number of bad packets received per second.
    rx_dropsec - Number  of  received  packets dropped per second because of
          a lack of space in linux buffers.
    tx_dropsec - Number of transmitted packets dropped per second because of
          a lack of space in linux buffers.

    Example call

    Call with thresholds on high values:
    check_network.pl -e -h -w 10 -c 20

  -s Network TCP established socket count.
    Data is collected for TCP sockets currently in use by the system. You
    will be required to pass the warning and critical values.  The choice is also
    available to set alerting against the high (-h) or low (-l) range.  An
    example of low would be alerting if errors are below a certain threshold.
    An example of high would be alerting if errors exceeds a certain threshold.

    Details on metrics collected are as follows.  All will report alerts.

    TCP_Active_Sockets - Number of TCP sockets currently in use.

    Example call

    Call with thresholds on high values:
    check_network.pl -s -h -w 100 -c 200

	-c <interger>
		Sets the critical threshold value.  This will depend if checking for high
		limit (-h) or low limit (-l).
	-w <interger>
		Sets the warning threshold value.  This will depend if checking for high
		limit (-h) or low limit (-l).
	-i <interger>
		This sets the interval for a single data run to collect.
		The result is the average of the collected sample.
		The default is 10.
	-h Set threshold checking to high limit.
	-l Set threshold checking to low limit.
	-d Debug

```

#### Installation and Configuration

##### File location and requirements

* check_network.pl - Default location is /usr/local/nagios/libexec.
	* Other location NAGIOS_HOME/libexec
	
* Linux sar command.
	
##### Nagios configuration examples

**Command Example**
	
Command Name | Command Line
------------ | --------------
check_nrpe_network | $USER1$/check_nrpe -H $HOSTADDRESS$ -t 60 -c check_network -a "$ARG1$"
	
	
Service Configuration Example 1 - Check CPU Utilization
	
Check | Command Name | Argument
----- | ------------ | --------------	
Check Network Bandwidth nrpe | check_nrpe_network | 
	
	
**NRPE Client Configuration**

Add to the nrpe common.cfg
```
	### CPU Utilization ###
	command[check_network]=/usr/local/nagios/libexec/check_network.pl $ARG1$
```	
	
[Nagios Checks Home](http://throwsb.github.io/nagios-checks/)
