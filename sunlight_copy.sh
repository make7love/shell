#!/bin/bash


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

backup_dir="/home/sunlight_update_backup/`date "+%Y%m%d"`"

if [ -d $backup_dir ];then
	send_info "$backup_dir existed, It will be deleted..."
	rm -rf "$backup_dir"
fi

if [ ! -d $backup_dir ];then
	mkdir -p $backup_dir
	chmod 755 $backup_dir
	send_info "create backup_dir : $backup_dir"
fi

function sunlight_backup_dir()
{
	if [ ! -e "$backup_dir/$1" ];then
		if [ -d $2 ];then
			tar zcvPf "$backup_dir/$1" $2
			if [ $? -eq 0 ];then
				send_success "$2 => $backup_dir/$1 finished!"
			else
				send_error "$2 => $1 | tar command failed!"
			fi
		else
			send_warn "$2 is not directory , skip...!"
		fi
	else
		send_info "$1 has existed! skip..."
	fi
}

