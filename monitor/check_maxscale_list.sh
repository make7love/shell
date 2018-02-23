#!/bin/bash

#监控maxadmin列表下的server状态值；
#如果发现服务节点"Down"掉，立即发送告警；
#只需要部署到三个应用节点之一即可；
#如果部署到管理节点，或监控文件中，管理节点项配置为空，则停止执行；
#2018/02/23

function get_current_time_stamp()
{
	echo `date "+%Y/%m/%d %H:%M:%S"`
}

function send_error()
{
	echo -e "\e[1;45m [ Error ] `get_current_time_stamp` -  $1  -\e[0m"
}

function send_success()
{
	echo -e "\e[1;32m [ Success ] `get_current_time_stamp` -  $1  -\e[0m"
}

function send_info()
{
	echo -e "\e[1;34m [ Info ] `get_current_time_stamp` -  $1  -\e[0m"
}

function send_warn()
{
	echo -e "\e[1;33m [ Warn ] `get_current_time_stamp` -  $1  -\e[0m"
}

check_maxscale_log="/var/log/sunlight/monitor/check_maxscale.log"
if [ ! -d "/var/log/sunlight/monitor" ];then
	mkdir -p /var/log/sunlight/monitor
	chmod 755 /var/log/sunlight/monitor
fi

monitor_conf="/usr/local/sunlight/conf/monitor.ini"
if [ ! -f "$monitor_conf" ];then
	send_error "file '/usr/local/sunlight/conf/monitor.ini' not found..."
	exit 1
fi

while read line
do
	if [ $(echo $line | egrep "^s" | wc -l) -eq 1 ];then
		eval "$line"
	fi
done < $monitor_conf

if [ "$sp_node_role" -eq "1" ];then
	send_error "此应用程序不能安装在管理节点！"
	exit 1
fi

if [ -z "$sp_manage_node" ];then
	send_error "管理节点配置项为空，请检查！"
	exit 1
fi

if [ ! -f "/usr/local/sunlight/sshkeys/init.pk" ];then
	send_error "/usr/local/sunlight/sshkeys/init.pk not found..."
	exit 1
fi

warn_msg="<h1>盛阳科技-运营商监控系统</h1><hr/>"
warn_msg="$warn_msg<p>运营商名称：$sp_name</p>"
warn_msg="$warn_msg<p>告警主机：`hostname`</p>"
warn_msg="$warn_msg<p>告警事件：<span style='color:#FF0000'>数据库集群中，有节点服务宕掉了！</span></p>"


down_count=$(maxadmin list servers | awk -F '|' '$5 != "" {print $5}' | grep Down |wc -l)

echo "" >> $check_maxscale_log
if [ $down_count -gt 0 ];then
	maxscale_string=$(maxadmin list servers)
	echo $maxscale_string >> $check_maxscale_log
	warn_msg="$warn_msg<pre>$maxscale_string</pre>"
	warn_msg="$warn_msg<p><strong style='color:#FF0000'>请立即登录节点检查！</span></strong></p>"
	ssh -i /usr/local/sunlight/sshkeys/init.pk -p2222 $sp_manage_node "/sunlight/python/send_mail.py --title=\"$sp_name-Maxscale监控告警\" --receivor=\"ts\" --content=\"$warn_msg\""
else
	echo "[ INFO ] `get_current_time_stamp` down mariadb server number: $down_count" >> $check_maxscale_log
	echo "[ INFO ] `get_current_time_stamp` Maxscale list monitor : OK"	>> $check_maxscale_log
fi