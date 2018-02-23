#!/bin/bash

#监控特定目录大小；
#当目录占用磁盘空间超过预定义值时，立即启动邮件告警。
#使用时，需注意管理节点或应用节点能否直连外网，决定发送邮件的方式；


#规定/var/log 40G;
log_path="/var/log"
log_space=$(echo "40*1024*1024" | bc)

#/usr/local/content 80G;
content_path="/usr/local/content"
content_space=$(echo "80*1024*1024" | bc)

#/var/www 40G;
www_path="/var/www"
www_space=$(echo "40*1024*1024" | bc)

#/var/weedfs 40G;
weedfs_path="/var/weedfs"
weedfs_space=$(echo "40*1024*1024" | bc)

#/var/lib/mysql 40G;
mysql_path="/var/lib/mysql"
mysql_space=$(echo "40*1024*1024" | bc)

#/sunlight 10G;
sunlight_path="/sunlight"
sunlight_space=$(echo "10*1024*1024" | bc)

#/usr/local/sunlight 10G;
usr_sunlight_path="/usr/local/sunlight"
usr_sunlight_space=$(echo "10*1024*1024" | bc)


#check script log file;
check_path_log="/var/log/sunlight/monitor/check_path_space.log"
check_path_dir=${check_path_log%/*}
if [ ! -d $check_path_dir ];then
	mkdir $check_path_dir
	chmod 755 $check_path_dir
fi

function get_timestamp()
{
	echo "`date "+%Y/%m/%d %H:%M:%S"`"
}

#parse config file;
monitor_conf="/usr/local/sunlight/conf/monitor.ini"
if [ ! -f $monitor_conf ];then
	echo "[ Error ] `get_timestamp` file $monitor_conf not found." >> $check_path_log
	echo "[ Error ] `get_timestamp` file $monitor_conf not found."
	exit 1
fi

while read line
do
	if [ $(echo $line | egrep "^s" | wc -l) -eq 1 ];then
		eval "$line"
	fi
done < $monitor_conf

if [ -z "$sp_name" ];then
	echo "[ Error ] `get_timestamp` global variable 'sp_name' not found."
	echo "[ Error ] `get_timestamp` global variable 'sp_name' not found." >> $check_path_log
	exit 1
fi

if [ -z "$sp_node_role" ];then
	echo "[ Error ] `get_timestamp` global variable 'sp_node_role' not found."
	echo "[ Error ] `get_timestamp` global variable 'sp_node_role' not found." >> $check_path_log
	exit 1
fi

if [ $sp_node_role -ne 1 ];then
	if [ -z "$sp_manage_node" ];then
		echo "[ Error ] `get_timestamp` global variable 'sp_manage_node' not found." 
		echo "[ Error ] `get_timestamp` global variable 'sp_manage_node' not found." >> $check_path_log
		exit 1
	fi
fi

if [[ $sp_node_role -eq 1  && ! -f /sunlight/python/send_mail.py ]];then
	echo "[ Error ] `get_timestamp` file /sunlight/python/send_mail.py not found. "
	echo "[ Error ] `get_timestamp` file /sunlight/python/send_mail.py not found. " >> $check_path_log
	exit 1
fi

#email message;
check_path_msg="<h1>盛阳科技-运营商-监控告警</h1>"
check_path_msg="$check_path_msg<p>运营商名称：$sp_name</p>"
check_path_msg="$check_path_msg<div style='padding:10px；border:1px #FF0000 dotted;'>功能：监控特定的数据目录，当目录占用磁盘空间超过预定义值时，立即启动邮件告警。</div>"


#define global event;
global_event=0

function check_space_handler()
{
	echo "" >> $check_path_log
	echo "`get_timestamp`  check_space_handler arguments:  $* " >> $check_path_log
	if [ $# -ne 2 ];then
		echo "[ Error ] `get_timestamp` function check_space_handler  arguments number error!" 
		echo "[ Error ] `get_timestamp` function check_space_handler  arguments number error!"  >> $check_path_log
		exit 1
	fi
	echo ">>> [ $1 ] START" >> $check_path_log
	if [ -d $1 ];then
		real_space=$(du -s $1 | awk '{print int($1)}')
		echo "$1 real space: $real_space" >> $check_path_log
		echo "$1 defined space: $2" >> $check_path_log
		if [ $(echo "$real_space > $2" | bc ) -eq 1 ];then
			global_event=1
			log_msg="<p>-----------------------------------------</p>"
			log_msg="$log_msg<p>告警目录：$1</p>"
			log_msg="$log_msg<p>预定义告警值：$2 KB</p>"
			log_msg="$log_msg<p>当前目录空间：$real_space KB</p>"
			echo "[ global_event ] : $global_event" >> $check_path_log
			echo "$log_msg" >> $check_path_log
			check_path_msg="$check_path_msg$log_msg"
		fi
	else
		echo "directory $1 not found." >> $check_path_log
	fi
	echo "<<< [ $1 ] FINISH" >> $check_path_log
}

check_space_handler  $log_path  $log_space
check_space_handler  $content_path  $content_space
check_space_handler  $www_path  $www_space
check_space_handler  $weedfs_path  $weedfs_space
check_space_handler  $mysql_path  $mysql_space
check_space_handler  $sunlight_path  $sunlight_space
check_space_handler  $usr_sunlight_path  $usr_sunlight_space

if [ $global_event -eq 1 ];then
	# /sunlight/python/send_mail.py --title="运营商-$sp_name-监控告警"  --content="$check_path_msg"
	if [ $sp_node_role -eq 1 ];then
		 /sunlight/python/send_mail.py  --title="运营商-$sp_name-监控告警"  --content="$check_path_msg"
	else
		ssh -i /usr/local/sunlight/sshkeys/init.pk -p2222 $sp_manage_node "/sunlight/python/send_mail.py --title=\"运营商-$sp_name-监控告警\"  --content=\"$check_path_msg\""
	fi
fi

exit 0
