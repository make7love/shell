#!/bin/bash

#检查服务进程是否存在或稳定；
#若不存在，立即报警；

check_service_process="/var/log/sunlight/monitor/check_service_process.log"



ckdir=${check_service_process%/*}
if [ ! -d $ckdir ];then
	mkdir -p $ckdir
	chmod 755 $ckdir
fi

warn_msg="<h1>盛阳科技-运营商监控系统</h1><hr/>"
warn_msg="$warn_msg<p>告警主机：$(hostname)</p>"
warn_msg="$warn_msg<p>告警事件：运营商服务进程运行不稳定！</p>"

warn_event=0

function check_nginx()
{
	
}

function check_php()
{

}

function check_mysql()
{

}

function check_keepalived()
{

}

function check_maxscale()
{

}


