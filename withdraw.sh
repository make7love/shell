#!/bin/bash

#用于升级epg代码后，回退操作；
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

echo "Are you sure to withdraw epg? [y/n]"
read withdrawepg

if [[ $withdrawepg -ne "y" && $withdrawepg -ne "Y" ]];then
	send_info "withdrawepg terminated...!"
	exit 0
fi

#操作开始；

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

if [ -z $epg_real_dir ];then
	send_error "$epg_real_dir is empty..."
	exit 1
fi

if [ ! -d $epg_real_dir ];then
	send_error "$epg_real_dir not found..."
	exit 1
fi

epg_real_dir_prefix=${epg_real_dir%/*}
epg_real_dir_target=${epg_real_dir##*/}

if [ -z "$backup_dir" ];then
	send_error "$backup_dir is empty!"
	exit 1
fi

epg_backup_dir="$backup_dir/`date "+%Y%m%d"`"
if [ ! -d "$epg_backup_dir" ];then
	send_error "$backup_dir is empty!"
	exit 1
fi

epg_backup_tar="$backup_dir/`date "+%Y%m%d"`/${epg_real_dir_target}.tar.gz"
if [ ! -e $epg_backup_tar ];then
	send_error "$epg_backup_tar not found..."
	exit 1
fi



send_info "begin to mv $epg_real_dir..."
send_info "mv $epg_real_dir ${epg_withdraw_dir}_`date "+%Y-%m-%d_%H:%M:%S"`"
sleep 2
mv $epg_real_dir "${epg_withdraw_dir}_`date "+%Y-%m-%d_%H:%M:%S"`"

if [ $? -ne 0 ];then
	send_error " mv $epg_real_dir ${epg_withdraw_dir}_`date "+%Y-%m-%d_%H:%M:%S"` failed..."
	exit 1
else
	send_success " mv $epg_real_dir ${epg_withdraw_dir}_`date "+%Y-%m-%d_%H:%M:%S"` finished..."
fi

send_info "begin to uncompress $epg_backup_tar..."
sleep 2

if [ -d $epg_real_dir ];then
	send_error "$epg_real_dir exist before uncompress..."
	exit 1
fi

tar -zxvf $epg_backup_tar -C "$epg_real_dir_prefix/"

if [ $? -ne 0 ];then
	send_error "$epg_backup_tar uncompress failed..."
	exit 1
else
	send_success "$epg_backup_tar uncompress finished..."
fi

if [ -d $epg_real_dir ];then
	send_success "withdraw operation finished..."
	exit 0
else
	send_error "withdraw operation failed..."
	send_error "Pleade check!"
	exit 1
fi

