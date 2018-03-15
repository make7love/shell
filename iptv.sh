#!/bin/bash

#此脚本用于EPG升级第二步，将应用节点/var/www/html/iptvtest 升级为 /var/www/html/iptv
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

echo "Are you sure to upgrade epg? [y/n]"
read upepg

if [[ $upepg -ne "y" && $upepg -ne "Y" ]];then
	send_info "upgrade terminated...!"
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

if [ -z "$backup_dir" ];then
	mkdir -p $backup_dir
fi

if [ ! -d "$backup_dir/`date +"%Y%m%d"`" ];then
	mkdir -p "/home/backup/`date +"%Y%m%d"`"
	chmod 755 "/home/backup/`date +"%Y%m%d"`"
fi

if [ -z "$epg_test_dir" ];then
	send_error "epg_test_dir is empty..."
	exit 1
fi

if [ ! -d "$epg_test_dir" ];then
	send_error "$epg_test_dir not found..."
	exit 1
fi

if [ -z "$epg_real_dir" ];then
	send_error "epg_real_dir is empty..."
	exit 1
fi

if [ ! -d "$epg_real_dir" ];then
	send_error "$epg_real_dir not found..."
	exit 1
fi

epg_real_dir_prefix=${epg_real_dir%/*}
epg_real_dir_target=${epg_real_dir##*/}

if [ -e "$backup_dir/`date +"%Y%m%d"`/${epg_real_dir_target}.tar.gz" ];then
	mv "$backup_dir/`date +"%Y%m%d"`/${epg_real_dir_target}.tar.gz" "$backup_dir/`date +"%Y%m%d"`/${epg_real_dir_target}.tar.gz_`date +"%Y-%m-%d_%H:%M:%S"`"
fi

send_info "begin to backup $epg_real_dir..."
sleep 2



tar zcvPf "$backup_dir/`date +"%Y%m%d"`/${epg_real_dir_target}.tar.gz" -C  $epg_real_dir_prefix $epg_real_dir_target

if [ $? -ne 0 ];then
	send_error "$epg_real_dir backup failed..."
	exit 1
fi

send_info "begin to move epg directory ..."
send_info "$epg_real_dir => ${epg_real_dir}_backup_`date "+%Y-%m-%d_%H:%M:%S"`"
sleep 2
mv $epg_real_dir  "${epg_real_dir}_backup_`date "+%Y-%m-%d_%H:%M:%S"`"

if [ $? -eq 0 ];then
	send_success "mv $epg_real_dir  ${epg_real_dir}_backup_`date "+%Y-%m-%d_%H:%M:%S"` OK!"
else
	send_error "mv $epg_real_dir  ${epg_real_dir}_backup_`date "+%Y-%m-%d_%H:%M:%S"` Failed...!"
	exit 1
fi

send_info "begin to move $epg_test_dir..."
send_info "$epg_test_dir => $epg_real_dir"
sleep 2
mv $epg_test_dir  $epg_real_dir

if [ $? -eq 0 ];then
	send_success "mv $epg_test_dir  $epg_real_dir OK!"
	chown root:root -R $epg_real_dir
	send_success "$(hostname) epg upgrade finished..."
else
	send_error "mv $epg_test_dir  $epg_real_dir Failed...!"
	exit 1
fi


