#!/bin/bash

#check weed process on manage node;


#********************************************************
#********************************************************
#********************************************************
#执行脚本前，一定要确认，各应用节点smon进程已经启动，
#并且拉起weed的指令写入 /usr/local/sunlight/proc_list
#使用supervisord管理进程。
#********************************************************
#********************************************************
#********************************************************

monitor_conf="/usr/local/sunlight/conf/monitor.ini"

#获取当前时间戳；
function get_time_stamp()
{
	echo "`date "+%Y/%m/%d %H:%M:%S"`"
}

#判断配置文件有效；
if [ ! -f "$monitor_conf" ];then
	echo "[ ERROR ] `get_time_stamp` $monitor_conf not found."
	exit 1
fi

if [ ! -f "/sunlight/python/send_mail.py" ];then
	echo "[ ERROR ] `get_time_stamp` /sunlight/python/send_mail.py not found."
	exit 1
fi

#读取配置项；
while read line
do
	if [ $(echo $line | egrep "^s" | wc -l) -eq 1 ];then
		eval "$line"
	fi
done < $monitor_conf

#检测weed总开关；
if [ $sp_weed_monitor -ne 1 ];then
	echo "[ INFO ] `get_time_stamp`  sp_weed_monitor=off and weed monitor stop."
	exit 0
fi

#必须是管理节点才有资格运行；
if [ $sp_node_role -ne 1 ];then
	echo "[ INFO ] `get_time_stamp`  sp_node_role error."
	exit 0
fi

#确保检查图片的url不为空；
#if [ -z "$sp_weed_url" ];then
#	echo "[ ERROR ] `get_time_stamp`  sp_weed_url is empty."
#	exit 1
#fi

#检查运营商名称；
if [ -z "sp_name" ];then
	echo "[ ERROR ] `get_time_stamp`  sp_name is empty."
	exit 1
fi

#下面检查三个应用节点的IP;
if [ -z "$sp_app1" ];then
	echo "[ ERROR ] `get_time_stamp`  sp_app1 is empty."
	exit 1
fi

if [ -z "$sp_app2" ];then
	echo "[ ERROR ] `get_time_stamp`  sp_app2 is empty."
	exit 1
fi

if [ -z "$sp_app3" ];then
	echo "[ ERROR ] `get_time_stamp`  sp_app3 is empty."
	exit 1
fi

if [ -z "$sp_weed_vip" ];then
	echo "[ ERROR ] `get_time_stamp`  sp_weed_vip is empty."
	exit 1
fi

app_node=("$sp_app3" "$sp_app2" "$sp_app1")

#判断密钥文件是否存在；
if [ ! -f /usr/local/sunlight/sshkeys/init.pk ];then
	echo "[ ERROR ] `get_time_stamp`  /usr/local/sunlight/sshkeys/init.pk not found."
	exit 1
fi


function kill_weedfs()
{
	for node in ${app_node[@]}
	do
		echo "ssh -p2222 -i /usr/local/sunlight/sshkeys/init.pk -o StrictHostKeyChecking=no $node \"ps -ef|grep \"/usr/local/sunlight/weed\" | grep -v grep | awk '{print \$2}' | xargs kill\"" 
		ssh -p2222 -i /usr/local/sunlight/sshkeys/init.pk -o StrictHostKeyChecking=no $node "ps -ef|grep \"/usr/local/sunlight/weed\" | grep -v grep | awk '{print $2}' | xargs kill"
		echo "-----[ INFO ] `get_time_stamp` ssh login and kill weed finished-----" 
	done
}

function check_weed_state_func()
{
	#首先使用weed状态检测命令；
	check_weed_state=$(curl http://${sp_weed_vip}:9333/dir/status?pretty=y)
	echo $check_weed_state 
	#检查三个节点
	echo "[ INFO ] `get_time_stamp` -----check-weed-status-start-----" 
	for application in ${app_node[@]}
	do
		if [ $(echo $check_weed_state | grep "$application" | wc -l) -lt 1 ];then
			weed_status=0
			weed_warn_msg="$weed_warn_msg<p style='color:#FF0000'> [ ERROR ] `get_time_stamp` 节点IP: $application  [ message ]节点在seaweedfs集群中不存在！</p>"
			echo "[ ERROR ] `get_time_stamp` IP: $application get out of cluster.." 
		else
			echo "[ SUCCESS ] `get_time_stamp` IP: $application is ok.." 
		fi
	done
	echo "[ INFO ] `get_time_stamp` -----check-weed-status-finished-----" 
}

while true
do
	echo "" 
	echo "weed check begin---------------------------------------------------------" 
	echo "app1: $sp_app1" 
	echo "app2: $sp_app2" 
	echo "app3: $sp_app3" 
	echo "sp_weed_vip: $sp_weed_vip" 
	echo "sp_name: $sp_name" 
	
	warn_msg="<h1>盛阳科技-运营商监控系统-告警信息</h1>"
	warn_msg="$warn_msg<p>运营商名称：$sp_name</p>"
	warn_msg="$warn_msg<p>告警发送节点：$(hostname)</p>"
	warn_msg="$warn_msg<p>告警内容:<span style='color:#FF0000'>图片服务运行出现问题！</span></p>"
	warn_msg="$warn_msg<p>告警触发规则：1). 定向请求图片服务器，当测试图片无法获取，则发送告警；</p>"
	warn_msg="$warn_msg<p>告警触发规则：2). 每次执行3次请求，每次请求超时时间为5秒；</p>"
	warn_msg="$warn_msg<p>告警触发规则：3). 定时请求weed节点，获取集群信息，若配置的子节点不存在，仍然会触发报警；</p>"
	warn_msg="$warn_msg<p style='color:#FF0000'>若无人工干预，五分钟后将重启seaweed集群服务！</p>"
	warn_msg="$warn_msg<hr/>"
	
	weed_status=1
	weed_warn_msg=""
	
	check_weed_state_func
	
	echo "The first time to check weed result - weed_status : $weed_status" 
	if [ $weed_status -ne 1 ];then
		#发送告警；
		echo "send warn email..." 
		/sunlight/python/send_mail.py  --title="运营商-$sp_name-图片服务告警"  --content="$warn_msg$weed_warn_msg"
		#等待5分钟；
		sleep 300
		#执行重启；
		echo "begin to kill weed process in 3 application node..." 
		kill_weedfs
		#等待1分钟；
		sleep 60
		#检查拉起效果；
		echo "begin to check pull effect..." 
		weed_status=1
		check_weed_state_func
		if [ $weed_status -ne 1 ];then
			echo "pull failed..." 
			echo "send warn email..." 
			#拉起失败，再次发送告警；
			/sunlight/python/send_mail.py  --title="运营商-$sp_name-图片服务告警"  --content="<h1>盛阳科技-运营商监控系统-告警信息</h1><p>运营商名称:$sp_name</p> \
			<p>告警发送节点：$(hostname)</p>
			<strong style='color:#FF0000'>告警内容： weed服务重启失败，请立即登录检查！</strong>"
		fi
	fi
	
	echo "The second time to check weed result - weed_status : $weed_status" 
	if [ $weed_status -eq 1 ];then
		echo "weed is OK." 
	else
		echo "weed is ERROR." 
	fi
	echo "weed check finished---------------------------------------------------------" 
	#每十分钟执行一次循环；
	sleep 600
done
