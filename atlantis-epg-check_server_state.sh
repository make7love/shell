#!/bin/bash

htname=$(hostname)
vip="10.108.144.5"
epg01="10.108.144.1"
epg02="10.108.144.2"
error_number=0

function send_warn()
{
	echo "Begin to send email......"
	if [ $(ip addr | grep $epg01 | wc -l)  -eq 1 ];then
		#EPG-01
		if [ -f /sunlight/python/slt_send_mail.py ];then
			if [ $(ping -w 1 -c 1 baidu.com | grep ttl | wc -l) -eq 1 ];then
				python /sunlight/python/slt_send_mail.py  "$1"
			fi
		fi
	else
		#EPG-02
		ssh -p 2222 -i /usr/local/sunlight/sshkeys/init.pk -o StrictHostKeyChecking=no $epg01 "ping -w 1 -c 1 baidu.com"
		if [ $? -eq 0 ];then
			ssh -p 2222 -i /usr/local/sunlight/sshkeys/init.pk -o StrictHostKeyChecking=no $epg01 "python /sunlight/python/slt_send_mail.py  \"$1\""
		fi
	fi
	echo "Send mail end......"
}

while true
do
	event_string="<p><span style='color:#FF0000'>发现运行时错误！</span></p>"
	error_number=0	
	check_vip=$(ip addr | grep $vip | wc -l)
	check_cron=$(ls -l /etc/cron.d |grep "^-" | wc -l)
	check_smon=$(ps -ef | grep /usr/local/sunlight/smon | grep -v grep | wc -l)
	check_route=$(ip route | grep $vip | wc -l)
	check_ip_conflict=$(ps -ef | grep "check_server_ip_conflict.sh" | grep -v grep | wc -l)
	
	#execute action
	#master
	if [ $check_vip -eq 1 ];then
		if [ $check_cron -lt 1 ];then
			if [ -d /sunlight/cron.d ];then
				mv /sunlight/cron.d/*  /etc/cron.d/
			fi
		fi
		
		if [ $check_smon -ne 1 ];then
			pkill -9 smon
			/usr/local/sunlight/smon -f /usr/local/sunlight/proc_list
		fi
		
		if [ $check_route -ne 1 ];then
			if [ $(ip addr | grep "10.108.144.1" | wc -l) -eq 1 ];then
				real_ip="10.108.144.1"
			fi
			if [ $(ip addr | grep "10.108.144.2" | wc -l) -eq 1 ];then
				real_ip="10.108.144.2"
			fi
			if [ ! -z "$real_ip" ];then
				ip route del 10.108.144.0/21 dev eth0  proto kernel  scope link  src $real_ip
				ip route add 10.108.144.0/21 dev eth0  proto kernel  scope link  src 10.108.144.5
			fi
			
		fi
	fi
	
	#execute action
	#slave
	if [ $check_vip -ne 1 ];then
		if [ $check_cron -gt 0 ];then
			if [ -d /sunlight/cron.d ];then
				mv  /etc/cron.d/* /sunlight/cron.d/
			fi
		fi
		
		if [ $check_smon -ne 1 ];then
			pkill -9 smon
			/usr/local/sunlight/smon -f /usr/local/sunlight/proc_list_slave
		fi
		
		if [ $check_route -eq 1 ];then
			ip route del 10.108.144.0/21 dev eth0  proto kernel  scope link  src 10.108.144.1
			ip route add 10.108.144.0/21 dev eth0  proto kernel  scope link  src 10.108.144.5
		fi
	fi
	
	
	#check state and send warn
	#master
	if [ $check_vip -eq 1 ];then
		echo "[ info ] `date "+%Y%m%d %H:%M:%S"` Server is in Master State!"
		echo "check cron......"
		echo "$check_cron"
		if [ $check_cron -lt 1 ];then
			if [ -d /sunlight/cron.d ];then
				mv /sunlight/cron.d/*  /etc/cron.d/
			fi
			error_number=1
			event_string="${event_string}<p>错误描述：服务器在Master状态下，/etc/cron.d/目录下定时任务文件不存在，请登录检查！</p>"
		fi
		echo "check smon......"
		echo "$check_smon"
		if [ $check_smon -ne 1 ];then
			error_number=1
			event_string="${event_string}<p>错误描述：服务器在Master状态下，smon进程不为1,请登录检查！</p>"
		fi
		echo "check route......"
		echo "$check_route"
		if [ $check_route -ne 1 ];then
			error_number=1
			event_string="${event_string}<p>错误描述：服务器在Master状态下，虚拟路由地址没有正确设置,请登录检查！</p>"
		fi
		echo "check_ip_conflict......"
		echo "$check_ip_conflict"
		if [[ $check_ip_conflict  -ne 1 && $check_ip_conflict -ne 2 ]];then
			error_number=1
			event_string="${event_string}<p>错误描述：服务器在Master状态下，检测IP地址冲突的脚本没有正确运行,请登录检查！</p>"
		fi
	fi

	#slave
	if [ $check_vip -ne 1 ];then
		echo "[ info ] `date "+%Y%m%d %H:%M:%S"` Server is in Slave State!"
		echo "check cron......"
		echo "$check_cron"
		if [ $check_cron -gt 0 ];then
			error_number=1
			event_string="${event_string}<p>错误描述：服务器在Slave状态下，/etc/cron.d/目录下定存在定时任务文件，请登录检查！</p>"
		fi
		
		echo "check smon......"
		echo "$check_smon"
		if [ $check_smon -ne 1 ];then
			error_number=1
			event_string="${event_string}<p>错误描述：服务器在Slave状态下,smon进程不为1,请登录检查！</p>"
		fi
		
		echo "check route......"
		echo "$check_route"
		if [ $check_route -eq 1 ];then
			error_number=1
			event_string="${event_string}<p>错误描述：服务器在Slave状态下，存在虚拟路由地址,请登录检查！</p>"
		fi
		
		echo "check_ip_conflict......"
		echo "$check_ip_conflict"
		if [[ $check_ip_conflict -ne 1 && $check_ip_conflict -ne 2 ]];then
			error_number=1
			event_string="${event_string}<p>错误描述：服务器在Slave状态下，检测IP地址冲突的脚本没有正确运行,请登录检查！</p>"
		fi
	fi


	event_string="${event_string}<p>消息来源：海南-三亚-亚特兰蒂斯酒店</p>"
	event_string="${event_string}<p>hostname: ${htname}</p>"

	if [ $error_number -eq 1 ];then
		echo $event_string
		send_warn  "$event_string"
	fi
	sleep 60
done
