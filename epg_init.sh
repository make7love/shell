#!/bin/bash

#此脚本用于EPG升级第一步，从管理节点拷贝iptvtest目录；
#by chao.dong
#472298551@qq.com

function get_time_stamp()
{
	echo `date "+%Y/%m/%d %H:%M:%S"`
}

function send_error()
{
	echo -e "\e[1;45m [ Error ] `get_time_stamp` -  $1  -\e[0m"
}

function send_success()
{
	echo -e "\e[1;32m [ Success ] `get_time_stamp` -  $1  -\e[0m"
}

function send_info()
{
	echo -e "\e[1;34m [ Info ] `get_time_stamp` -  $1  -\e[0m"
}

function send_warn()
{
	echo -e "\e[1;33m [ Warn ] `get_time_stamp` -  $1  -\e[0m"
}

if [ ! -f /usr/local/sunlight/conf/spinfo.ini ];then
	send_error "/usr/local/sunlight/conf/spinfo.ini not found..."
	exit 1
fi

while read line
do
	if [ $(echo "$line" | grep -o "=" | wc -l) -eq 1 ];then
		eval "$line"
	fi
done < /usr/local/sunlight/conf/spinfo.ini

if [ -z "$role" ];then
	send_error "server role is empty!"
	exit 1
fi

if [[ $role -ne 2 && $role -ne 2 ]];then
	send_error "server role define error!"
	exit 1
fi

if [ -z "$manage_ip" ];then
	send_error "manage ip is empty!"
	exit 1
fi

if [ -z "$manage_port" ];then
	send_error "manage port is empty!"
	exit 1
fi

if [ -z "$epg_test_dir" ];then
	send_error "epg_test_dir is empty!"
	exit 1
fi

if [ -z "$ssh_key" ];then
	send_error "ssh key file  is empty!"
	exit 1
fi

if [ -z "$epg_user" ];then
	send_error "epg_user  is empty!"
	exit 1
fi

if [ -z "$epg_group" ];then
	send_error "epg_group  is empty!"
	exit 1
fi

if [ $(grep "$epg_group" /etc/group | wc -l) -lt 1 ];then
	groupadd $epg_group 
fi

if [ $(grep "$epg_user" /etc/passwd | wc -l) -lt 1 ];then
	useradd -g $epg_group  -d "/home/$epg_user" -m $epg_user
fi

if [ ! -f $ssh_key ];then
	send_error "$ssh_key not found..."
	exit 1
fi

if [ ! -d $epg_test_dir ];then
	mkdir -p $epg_test_dir
fi

rsync -avzt --delete --progress -e "ssh -i $ssh_key -p $manage_port" "$manage_ip:$epg_test_dir/"  "$epg_test_dir/"

if [ $? -eq 0 ];then
	send_success "rsync dir : $epg_test_dir from $manage_ip finished!"
	exit 0
else
	send_error "rsync dir : $epg_test_dir from $manage_ip failed!"
	exit 1
fi
