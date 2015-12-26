#!/usr/bin/python

import sys

server = sys.argv[1]
port = sys.argv[2]

userName = sys.argv[5]
passWord = sys.argv[6]
authType = sys.argv[7]
srvurl = "t3://" + str(server) + ":" + str(port)

redirect('/dev/null', 'false')

if authType == "KEY":
	connect(userConfigFile=userName, userKeyFile=passWord, url=srvurl)
	serverRuntime()
elif authType == "USRPW":
	connect(userName, passWord, url=srvurl)
	serverRuntime()
else:
	print "No Connection"

state = sys.argv[3]
mgserver = sys.argv[4]


if state == "HealthState":
	hstate = get(state)
	print state + ":"+`hstate`
	##discconect()
	exit()
elif state == "OverallHealthState":
	hstate = get(state)
	print state + ":"+`hstate`
	##discconect()
	exit()
elif state == "ThreadHealthState":
	cd('/ThreadPoolRuntime/ThreadPoolRuntime')
	hstate = get('HealthState')
	print state + ":"+`hstate`
	##discconect()
	exit()
elif state == "JDBCHealthState":
	cd('/JDBCServiceRuntime/' + mgserver)
	hstate = get('HealthState')
	print state + ":"+`hstate`
	##discconect()
	exit()
elif state == "HeapFreePercent":
	cd('/JVMRuntime/' + mgserver)
	hpercent = int(get('HeapFreePercent'))
	##print 'HeapFreePercent:'+ `hpercent`
	print state + ":"+ `hpercent`
	##disconnect()
	exit()
elif state == "StuckThreadCount":
	cd('/ThreadPoolRuntime/ThreadPoolRuntime')
	hsthrd = int(get('StuckThreadCount'))
	print state + ":"+`hsthrd`
	exit()
elif state == "ThreadTotCount":
	cd('/ThreadPoolRuntime/ThreadPoolRuntime')
	hthrdcnt = int(get('ExecuteThreadTotalCount'))
	print state + ":"+`hthrdcnt`
	exit()
else:
	print "Invalid State:", state
	
	