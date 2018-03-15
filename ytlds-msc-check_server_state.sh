#!/bin/bash

msc_vip="10.108.144.6"
check_log="/var/log/sunlight/check_server_state.log"

check_vip=$(ip addr | grep $msc_vip | wc -l)

function print_date()
{
	echo `date "+%Y/%m/%d %H:%M:%S"`
}

while true
do
	check_vip=$(ip addr | grep $msc_vip | wc -l)
	echo "-------------------------------------------------------------"
	#master 
	if [ $check_vip -eq 1 ];then
		echo "[ info ] $(print_date) Server is in master state......"
		
		check_gslb=$(ps -ef | grep "gslb_server" | grep -v grep | wc -l)
		echo "[ info ] $(print_date) check_gslb number : $check_gslb"
		if [ $check_gslb -lt 1 ];then
			if [ -f /usr/local/sunlight/cdn/gslb/bin/shutdown.sh ];then
				/usr/local/sunlight/cdn/gslb/bin/shutdown.sh
			fi
			if [ -f /usr/local/sunlight/cdn/gslb/bin/startup.sh ];then
                                /usr/local/sunlight/cdn/gslb/bin/startup.sh
                        fi
		fi
		
		check_gnm=$(ps -ef | grep "gnm_server" | grep -v grep | wc -l)
		echo "[ info ] $(print_date) check_gnm number : $check_gnm"
		if [ $check_gnm -lt 1 ];then
			if [ -f /usr/local/sunlight/cdn/gnm/bin/shutdown.sh ];then
                                /usr/local/sunlight/cdn/gnm/bin/shutdown.sh
                        fi
                        if [ -f /usr/local/sunlight/cdn/gnm/bin/startup.sh ];then
                                /usr/local/sunlight/cdn/gnm/bin/startup.sh
                        fi
		fi
		
		check_nm=$(ps -ef | grep -E "\bnm_server" | grep -v grep | wc -l)
		echo "[ info ] $(print_date) check_nm number : $check_nm"
		if [ $check_nm -lt 1 ];then
			if [ -f /usr/local/sunlight/cdn/nm/bin/shutdown.sh ];then
                                /usr/local/sunlight/cdn/nm/bin/shutdown.sh
                        fi
                        if [ -f /usr/local/sunlight/cdn/nm/bin/startup.sh ];then
                                /usr/local/sunlight/cdn/nm/bin/startup.sh
                        fi
		fi
		
		check_vms=$(ps -ef | grep vms_server | grep -v grep | wc -l)
		echo "[ info ] $(print_date) check_vms number : $check_vms"
		if [ $check_vms -lt 1 ];then
			if [ -f /usr/local/sunlight/cdn/vms/bin/shutdown.sh ];then
                                /usr/local/sunlight/cdn/vms/bin/shutdown.sh
                        fi
                        if [ -f /usr/local/sunlight/cdn/vms/bin/startup.sh ];then
                                /usr/local/sunlight/cdn/vms/bin/startup.sh
                        fi

		fi

	fi

	#slave
	if [ $check_vip -ne 1 ];then
		echo "[ info ] $(print_date) Server is in slave state......"
		
		check_gslb=$(ps -ef | grep "gslb_server" | grep -v grep | wc -l)
		echo "[ info ] $(print_date) check_gslb number : $check_gslb"
		if [ $check_gslb -gt 0 ];then
			/usr/local/sunlight/cdn/gslb/bin/shutdown.sh
		fi
		
		check_gnm=$(ps -ef | grep "gnm_server" | grep -v grep | wc -l)
		echo "[ info ] $(print_date) check_gnm number : $check_gnm"
		if [ $check_gnm -gt 0 ];then
			/usr/local/sunlight/cdn/gnm/bin/shutdown.sh
		fi
		
		check_nm=$(ps -ef | grep -E "\bnm_server" | grep -v grep | wc -l)
		echo "[ info ] $(print_date) check_nm number : $check_nm"
		if [ $check_nm -gt 0 ];then
			/usr/local/sunlight/cdn/nm/bin/shutdown.sh
		fi
		
	fi
	sleep 60
done
