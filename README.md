# Nagios Checks
Monitoring Check Scripts used with Nagios and NagiosXI

## Welcome to my Github site.

The following are a list of Nagios check scripts that I have created over the years.  Please feel free to contact me with any feature requests, bug reports, or support for installation and configuration.  
  

Cheers!
David

### List of Nagios Check Scripts
* **check_wls.pl** - Checks the health of a Weblogic instance using jmx and wlst.  This has been tested using Weblogic 12c.  Please send feedback when running on other versions of WebLogic.  I do not have access to older version to test on.  Full details of the script can be found here [check wls](https://github.com/throwsb/nagios-checks/blob/master/check_wls.md)

* **check_hpLocaldisk.pl** - is a check script to monitor local disk status on HP servers.  It connects to the local disk controller using hpacucli or hpssacli 
    and pulls the status of the disks.  Full details of the script can be found here [check hpLocaldisk](https://github.com/throwsb/nagios-checks/blob/master/check_hpLocaldisk.md)

* **check_cpu_util.pl** - Checks the CPU utilization across all CPU's on a server and returns the percentage used. Full details of the script can be found here [check cpu util](https://github.com/throwsb/nagios-checks/blob/master/check_cpu_util.md)

* **check_memoryfree.pl** - Checks the memory and swap usage on a Linux server using the free command.  Full details of the script can be found here [check memoryfree](https://github.com/throwsb/nagios-checks/blob/master/check_memorylinux.md)

* **check_memory-linux.pl** - Checks the memory usage on a Linux server with a SNMP query.  Full details of the script can be found here [check memory Linux](https://github.com/throwsb/nagios-checks/blob/master/check_memorylinux.md)

* **check_cpu-hpux.pl** - Checks CPU usage on a HP-UX server.  Full details of the script can be found here [check CPU HP-UX](https://github.com/throwsb/nagios-checks/blob/master/check_hpux.md)

* **check_memory-hpux.pl** - Checks the memory usage on a HP-UX server with a SNMP query.  Full details of the script can be found here [check memory HP-UX](https://github.com/throwsb/nagios-checks/blob/master/check_hpux.md)

* **check_memory-isilon.pl** - Checks the memory usage on a EMC Isilon Node with a SNMP query.  Full details of the script can be found here [check memory EMC Isilon](https://github.com/throwsb/nagios-checks/blob/master/check_isilon.md)

* **isilon_quota_check.pl** - Checks the disk quotas usage on a EMC Isilon cluster.  Full details of the script can be found here [check disk quota EMC Isilon](https://github.com/throwsb/nagios-checks/blob/master/check_isilon.md)

