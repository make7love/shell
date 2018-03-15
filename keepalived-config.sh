#!/bin/bash
#version : keepalived-1.3.0
#keepalived编译安装后，需要执行此脚本完成配置工作；

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




if [ -z "$1" ];then
	kp_dir="/usr/local/keepalived-1.3.0"
else
	kp_dir=$1
fi

if [ ! -d $kp_dir ];then
	send_error "keepalived direcotry $kp_dir is empty...!"
	exit 1
fi

if [ -f "$1/etc/keepalived/keepalived.conf" ];then
	if [ ! -d /etc/keepalived ];then
		mkdir /etc/keepalived
		chmod 755 /etc/keepalived
	fi
	cp -f "$1/etc/keepalived/keepalived.conf" /etc/keepalived/
	chmod 755 -R /etc/keepalived
else
	send_error "$1/etc/keepalived/keepalived.conf not found...!"
	exit 1
fi


if [ -f "$1/etc/sysconfig/keepalived" ];then
	cp -f "$1/etc/sysconfig/keepalived" /etc/sysconfig/
else
	send_error "$1/etc/sysconfig/keepalived not found...!"
	exit 1
fi


if [ -e "$1/sbin/keepalived" ];then
	cp -f "$1/sbin/keepalived" /usr/sbin/
	chmod +x  /usr/sbin/keepalived
else
	send_error "$1/sbin/keepalived not found...!"
	exit 1
fi

send_info "begin to update /etc/sysconfig/keepalived..."
sed -i 's/KEEPALIVED_OPTIONS/#KEEPALIVED_OPTIONS/' /etc/sysconfig/keepalived
sed -i '$a\KEEPALIVED_OPTIONS="-D -d -S 0"' /etc/sysconfig/keepalived

send_info "begin to restart rsyslog..."
sed -i '$a\local0.*            /var/log/keepalived/keeplived.log'  /etc/rsyslog.conf
systemctl restart rsyslog.service
 
 
 