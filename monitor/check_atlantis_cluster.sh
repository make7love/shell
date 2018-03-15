#!/bin/bash
#this script is used to monitor mariadb galera cluster on atlantis project.
#每两分钟执行一次，不能写入系统定时任务，只能写入shell脚本，定时执行，并加入到supervisord管理；
#by chao.dong
#472298551@qq.com

while true
do
	function get_timestamp()
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


	mysql_process_string="/usr/sbin/mysqld"
	monitor_conf="/usr/local/sunlight/conf/monitor.ini"
	check_cluster_log="/var/log/sunlight/monitor/cluster.log"

	if [ ! -f $monitor_conf ];then
		send_error "$monitor_conf not found..."
		exit 1
	fi

	cluster_log_dir=${check_cluster_log%/*}
	if [ ! -d $cluster_log_dir ];then
		mkdir -p $cluster_log_dir
		chmod 755 $cluster_log_dir
	fi

	while read line
	do
		if [ $(echo $line | egrep "^s" | wc -l) -eq 1 ];then
			eval "$line"
		fi
	done < $monitor_conf

	echo "" 
	echo "---------------------------------------------------"
	if [ -z "$sp_mysqld_monitor" ];then
		echo "[ Error ] `get_timestamp` global variable 'sp_mysqld_monitor' not found."
		exit 1
	fi

	if [ $sp_mysqld_monitor -ne 1 ];then
		echo "mysqld monitor switch is OFF!"
		exit 1
	fi

	if [ -z "$sp_mysqld_host" ];then
		echo "[ Error ] `get_timestamp` global variable 'sp_mysqld_host' not found."
		exit 1
	fi

	if [ -z "$sp_mysqld_user" ];then
		echo "[ Error ] `get_timestamp` global variable 'sp_mysqld_user' not found."
		exit 1
	fi

	if [ ! -f /sunlight/python/send_mail.py ];then
		echo "[ Error ] `get_timestamp` file /sunlight/python/send_mail.py not found. "
		exit 1
	fi

	warn_msg="<h1>盛阳科技-服务监控系统</h1><hr/>"
	warn_msg="$warn_msg<p>告警来源：海南-三亚-亚特兰蒂斯酒店</p>"
	warn_msg="$warn_msg<p>告警主机：$(hostname)</p>"
	warn_msg="$warn_msg<p><span style='color:#FF0000'>告警主消息：Mysql运行异常！</span></p>"
	warn_state=0


	#1). check mysqld process
	check_mysqld_process=$(ps -ef | grep $mysql_process_string | grep -v grep | wc -l)
	if [ $check_mysqld_process -lt 1 ];then
		warn_state=1
		echo "[ Error ] `get_timestamp` mysqld process not found."
		warn_msg="$warn_msg<p>[ ERROR ] `get_timestamp` Mysqld进程消失！</p>"
	else
		echo "[ INFO ] `get_timestamp` mysqld is running..."
	fi

	#2). check cluster status
	if [ -z "$sp_mysqld_pwd" ];then
		pwd_string=""
	else
		pwd_string="-p$sp_mysqld_pwd"
	fi

	wsrep_string=$(mysql -u${sp_mysqld_user} $pwd_string -e "show status like 'wsrep_%';")
	if [ $? -eq 0 ];then
		cluster_status=$(echo "$wsrep_string" | grep "wsrep_cluster_status" | cut -f 2)
		if [ "$cluster_status" != "Primary" ];then
			warn_state=1
			warn_msg="$warn_msg<p>[ ERROR ] `get_timestamp`  wsrep_cluster_status != Primary </p>"
			echo "[ ERROR ] `get_timestamp` wsrep_cluster_status != Primary" 
		else
			echo "[ INFO ] `get_timestamp` wsrep_cluster_status = Primary"
		fi
		
		node_connected=$(echo "$wsrep_string" | grep "wsrep_connected" | cut -f 2 )
		if [ "$node_connected" != "ON" ];then
			warn_state=1
			warn_msg="$warn_msg<p>[ ERROR ] `get_timestamp`  wsrep_connected != ON </p>"
			echo "[ ERROR ] `get_timestamp` wsrep_connected != ON" 
		else
			echo "[ INFO ] `get_timestamp` wsrep_connected = ON" 
		fi
		
		cluster_ready=$(echo "$wsrep_string" | grep "wsrep_ready" | cut -f 2 )
		if [ "$cluster_ready" != "ON" ];then
			warn_state=1
			warn_msg="$warn_msg<p>[ ERROR ] `get_timestamp`  wsrep_ready != ON </p>"
			echo "[ ERROR ] `get_timestamp` wsrep_ready != ON" 
		else
			echo "[ INFO ] `get_timestamp` wsrep_ready = ON"
		fi
		
		node_local_state=$(echo "$wsrep_string" | grep "wsrep_local_state_comment" | cut -f 2 )
		if [ "$node_local_state" == "Initialized" ];then
			warn_state=1
			warn_msg="$warn_msg<p>[ ERROR ] `get_timestamp`  wsrep_local_state_comment == Initialized </p><p>节点脱离集群！</p>"
			echo "[ ERROR ] `get_timestamp` wsrep_local_state_comment == Initialized. 节点脱离集群！" 
		else
			echo "[ INFO ] `get_timestamp` `echo "$wsrep_string" | grep "wsrep_local_state_comment"`" 
		fi
	else
		warn_state=1
		echo "[ Error ] `get_timestamp` select wsrep status failed!"
		warn_msg="$warn_msg<p>[ INFO ] `get_timestamp`查询Mysql状态，操作失败！</p>"
	fi
	
	if [ $warn_state -eq 1 ];then
		check_server_role=$(ip addr | grep "10.108.144.1" | wc -l)
		if [ $check_server_role -eq 1 ];then
			/sunlight/python/send_mail.py  --title="亚特兰蒂斯-数据库集群告警"  --reveivor="ts+hnan" --content="$warn_msg"
		else
			ssh -p 2222 -i /usr/local/sunlight/sshkeys/init.pk -o StrictHostKeyChecking=no 10.108.144.1 /sunlight/python/send_mail.py  --title="亚特兰蒂斯-数据库集群告警"  --reveivor="ts+hnan" --content="$warn_msg"
		fi
	fi
	echo "check over.."
	sleep 120
done