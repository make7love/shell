#!/bin/bash
if [ ! -d "/home/smonitor/monitordata" ];then
	mkdir -p /home/smonitor/monitordata
	chmod 0777 -R /home/smonitor/monitordata
fi


pid_number=$(ps -ef|grep "dstat -tcmnf" | grep -v grep | wc -l )
if [ $pid_number -gt 0 ];then
	ps -ef|grep "dstat -tcmnf" | grep -v grep |awk '{ print $2}' | xargs kill
	sleep 3
fi

pid_number=$(ps -ef|grep "dstat -tcmnf" | grep -v grep | wc -l )
if [ $pid_number -lt 1 ];then
	parent_fold=$(date "+%Y-%m-%d")
	if [ ! -d "/home/smonitor/monitordata/$parent_fold" ];then
		mkdir -p /home/smonitor/monitordata/$parent_fold
		chmod 0777 /home/smonitor/monitordata/$parent_fold
	fi
	file_name=$(date "+%Y-%m-%d_%H")
	file_path=/home/smonitor/monitordata/$parent_fold/$file_name".txt"
    /usr/local/dstat/dstat -tcmnf --output $file_path  60
else
	datetime=$(date "+%Y-%m-%d_%H-%M-%S")
	echo "$datetime  [Error!] Because dstat pid exists !" >> /home/smonitor/load_monitor.log
fi
