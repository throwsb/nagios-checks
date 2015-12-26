##check_cpu-hpux.pl

#### **check_cpu-hpux.pl** - Checks CPU usage on a HP-UX server.  

#### Usage: 
```
	check_cpu-hpux.pl -c <critical value> -w <warning value>
	
	-c <interger>
		Exit with a critical status if greater than the total CPU idle.  The
		critical value can not be higher than the warning status.
	-w <interger>
		Exit with a warning status if greater than the total CPU idle.  The
		warning value can not be lower than the critical value.
		
```



##check_memory-hpux.pl

#### **check_memory-hpux.pl** - Checks the memory usage on a HP-UX server with a SNMP query.  

#### Usage: 
```
	check_memory-hpux.pl -c <critical value> -w <warning value> 
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

[Nagios Checks Home](http://throwsb.github.io/nagios-checks/)