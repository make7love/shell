#!/bin/bash

#用来监控系统负载；
#获取top参数值，判断后，发送告警；
#472298551@qq.com
#使用时，需决定发送邮件的方式；

disk_space_percent=70
mem_usage_percent=70
cpu_idle_percent=30

disk_warn=0
mem_warn=0
cpu_warn=0


log_file="/var/log/sunlight/monitor/sys.log"
check_log_dir=${log_file%/*}
if [ ! -d $check_log_dir ];then
	mkdir $check_log_dir
	chmod 755 $check_log_dir
fi

if [ ! -f /sunlight/python/send_mail.py ];then
	echo "[ Error ] /sunlight/python/send_mail.py not found!"
	echo "[ Error ] /sunlight/python/send_mail.py not found!" >> $log_file
	exit 1
fi

if [ ! -d /var/log/sunlight/monitor ];then
	mkdir /var/log/sunlight/monitor
	chmod 755 /var/log/sunlight/monitor
fi

#parse config file;
monitor_conf="/usr/local/sunlight/conf/monitor.ini"
if [ ! -f $monitor_conf ];then
	echo "[ Error ] `get_timestamp` file $monitor_conf not found." >> $check_path_log
	echo "[ Error ] `get_timestamp` file $monitor_conf not found."
	exit 1
fi

function get_timestamp()
{
	echo "`date "+%Y/%m/%d %H:%M:%S"`"
}

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


host_name=$(hostname)
warn_msg="<h1>盛阳科技-运营商监控系统-告警信息</h1>"
warn_msg="$warn_msg<p>运营商名称：$sp_name</p>"
warn_msg="$warn_msg<p>告警节点：$host_name</p>"


function check_disk_space()
{
	echo ">>>>>> DISK [ start ]:" >> $log_file
	disk_check_time=$(get_timestamp)
	disk_warn_msg=""
	disk_html_table="<table>"
	disk_html_table_2="</table>"
	disk_html_string="<thead><tr><th>Filesystem</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mounted on</th></tr></thead>"
	disk_html_tbody="<tbody>"
	disk_html_tbody_2="</tbody>"
	while read line
	do
		if [ $(echo $line | grep -E "^Filesystem" | wc -l) -eq 0 ];then
			space_percent=$(echo $line | awk '{print $5}' | cut -d % -f 1 | awk '{print int($1)}')
			if [ $(echo "$space_percent > $disk_space_percent" | bc) -eq 1 ];then
				disk_warn=1
				ft=$(echo $line | awk '{print $1}')
				sz=$(echo $line | awk '{print $2}')
				ud=$(echo $line | awk '{print $3}')
				al=$(echo $line | awk '{print $4}')
				us=$(echo $line | awk '{print $5}')
				mo=$(echo $line | awk '{print $6}')
				disk_warn_msg="$disk_warn_msg<tr><td>$ft</td><td>$sz</td><td>$ud</td><td>$al</td><td>$us</td><td>$mo</td></tr>"
			fi
		fi
	done <<EOF
	`df -h`
EOF
	echo "[ disk_warn ] = $disk_warn" >> $log_file
	if [ $disk_warn -eq 1 ];then
		warn_msg="$warn_msg<p>------------------------------------------------------</p>"
		warn_msg="$warn_msg<p><strong style='color:FF0000'>磁盘告警信息：有磁盘分区使用率超过 ${disk_space_percent}% !</strong></p>"
		warn_msg="$warn_msg<p>磁盘检测时间：${disk_check_time}</p>"
		warn_msg="$warn_msg$disk_html_table$disk_html_string$disk_html_tbody$disk_warn_msg$disk_html_tbody_2$disk_html_table_2"
		echo $disk_warn_msg >> $log_file
	fi
	
	echo "<<<<<< DISK [ end ] " >> $log_file
}


function check_mem_usage()
{
	echo " " >> $log_file
	echo ">>>>>> MEMORY [ start ]:" >> $log_file
	mem_warn_msg=""
	mem_check_time=$(get_timestamp)
	mem_used=$(free -m | awk 'NR==3 {print int($3)}')
	mem_free=$(free -m | awk 'NR==3 {print int($4)}')
	mem_total=$(echo "$mem_used + $mem_free" | bc)
	mem_usage=$(echo "scale=2; $mem_used/$mem_total*100" | bc)
	if [ $(echo "$mem_usage > $mem_usage_percent" | bc) -eq 1 ];then
		mem_warn=1
		mem_warn_msg="$mem_warn_msg<p>------------------------------------------------------</p>"
		mem_warn_msg="$mem_warn_msg<p>内存检测时间：${mem_check_time}</p>"
		mem_warn_msg="$mem_warn_msg<p><strong style='color:FF0000'>内存告警信息：内存使用率超过${mem_usage_percent}%</strong></p>"
	fi
	echo "[ mem_warn ] = $mem_warn" >> $log_file
	if [ $mem_warn -eq 1 ];then
		warn_msg="$warn_msg$mem_warn_msg"
		echo $mem_warn_msg >> $log_file
	fi
	echo "<<<<<< MEMORY [ end ] " >> $log_file
}

#top -b -n 1 当取一条数据时会有问题，每次取出的都是同一个值；
function check_cpu_usage()
{
	echo " " >> $log_file
	echo ">>>>>> CPU [ start ]:" >> $log_file
	cpu_warn_msg=""
	while read line
	do
		if [ $(echo $line | egrep '^top' | wc -l) -eq 1 ];then
			cpu_check_time=$(echo $line | awk '{print $3}')
		fi
		
		if [ $(echo $line | egrep '^%Cpu' | wc -l) -eq 1 ];then
			idle_data=$(echo $line | awk -F ',' '{print $4}' | awk '{print int($1)}')
			if [ ! -z "$idle_data" ];then
				if [ $(echo "$idle_data < $cpu_idle_percent" | bc) -eq 1 ];then
					cpu_warn=1
					cpu_warn_msg="$cpu_warn_msg<p>------------------------------------------------------</p>"
					cpu_warn_msg="$cpu_warn_msg<p><strong style='color:FF0000'>CPU告警时间：${cpu_check_time}</strong></p>"
					cpu_warn_msg="$cpu_warn_msg<p>CPU告警信息：CPU空闲时间小于 ${cpu_idle_percent}% !</p>"
					cpu_warn_msg="$cpu_warn_msg<p>CPU消耗值：${line}</p>"
				fi
			else
				echo "[ Error ] `get_timestamp` cpu idle data is empty! " >> $log_file
				/sunlight/python/send_mail.py --title="盛阳科技-$sp_name-监控告警" --receivor="ts" --content="function check_cpu_usage in monitor_sys.sh does not work!"
			fi
		fi
	done <<EOF
	`top -b -n 10 | egrep "^%Cpu|^top"`
EOF
	echo "[ cpu_warn ] = $cpu_warn" >> $log_file
	if [ $cpu_warn -eq 1 ];then
		warn_msg="$warn_msg$cpu_warn_msg"
		echo $cpu_warn_msg >> $log_file
	fi
	echo ">>>>>> CPU [ end ]" >> $log_file
}

echo "" >> $log_file
echo "---------------------------------BEGIN---`get_timestamp`--------------------" >> $log_file
check_disk_space
check_mem_usage
check_cpu_usage
echo "---------------------------------END----------------------------------------" >> $log_file


if [[ $disk_warn -eq 1  || $mem_warn -eq 1 || $cpu_warn -eq 1 ]];then
	/sunlight/python/send_mail.py --title="盛阳科技-$sp_name-监控告警" --content="$warn_msg" 
fi
