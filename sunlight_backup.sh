#!/bin/bash

#亚特兰蒂斯项目，升级安装前，备份所有内容；
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

backup_dir="/home/sunlight_update_backup/`date "+%Y%m%d"`"
server_conf="/usr/local/sunlight/conf/server.conf"

if [ -d $backup_dir ];then
	send_info "$backup_dir existed, It will be deleted..."
	rm -rf "$backup_dir"
fi

if [ ! -d $backup_dir ];then
	mkdir -p $backup_dir
	chmod 755 $backup_dir
fi



#pass two parameters:
#1: compress packages name.
#2: directory need to be compressed.

function sunlight_backup_dir()
{
	if [ ! -e "$backup_dir/$1" ];then
		if [ -d $(echo $2 | sed s/[[:space:]]//g) ];then
			tar zcvf "$backup_dir/$1" -C $2
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


function sunlight_backup_file()
{
	if [ -f $1 ];then
		cp -f $1 "$backup_dir/"
		send_success "$1 => $backup_dir/  finished..."
	else
		send_warn "$1 is not file , skip..."
	fi
}

function sunlight_backup_mysql()
{
	if [ -f $server_conf ];then
	while read line
	do
		eval "$line"
	done < $server_conf
	else
		dbuser="root"
		sql_passwd=""
		dbhost="127.0.0.1"
		sql_port="3306"
	fi

	sql_user="$dbuser"
	sql_passwd="$dbpass"
	sql_host="$dbhost"
	sql_port="$dbport"
	mysql_bak=1
	#check mysql daemon
	check_sql_daemon=$(mysql -h"$sql_host" -u"$sql_user" --password="$sql_passwd" -e "select version();")
	if [ $? -ne 0 ];then
		send_error "[ msg ] We didn't find mysql daemon!" 
		mysql_bak=2
	fi
	
	#check xtrabackup package
	check_xtrabackup_rpm=$(rpm -qa|grep xtrabackup | wc -l)
	if [ $check_xtrabackup_rpm -ne 1 ];then
		send_error "[ msg ] xtrabackup does not be installed!" 
		mysql_bak=2
	fi
	
	if [ $mysql_bak -eq 1 ];then
		sql_home="$backup_dir/mysql_data"
		if [ ! -d $sql_home ];then
			mkdir -p $sql_home
			chmod 755 $sql_home
		fi
		sql_backup_date=$(date "+%Y%m%d")
		if [ -e "$sql_home/${sql_backup_date}.tar.gz" ];then
			rm -f "$sql_home/${sql_backup_date}.tar.gz"
		fi
		sudo -u mysql innobackupex --user=$sql_user  --password="$sql_passwd"  --socket=/var/lib/mysql/mysql.sock --no-timestamp --stream=tar "$sql_home/" | gzip >  "$sql_home/${sql_backup_date}.tar.gz"
		if [ $? -eq 0 ];then
			send_success "[ Success ] `date "+%Y/%m/%d %H:%M:%S"`  [ msg ] Mysql backup has been finished !" 
		else
			send_error "[ Error ] `date "+%Y/%m/%d %H:%M:%S"`  [ msg ] Mysql backup has been failed !" 
		fi
	fi
}


tar_pkgs=("www.tar.gz" "sunlight.tar.gz" "usr.local.sunlight.tar.gz" "var.lib.mysql.tar.gz" "acserver.tar.gz" \
"etc.cron.d.tar.gz" "etc.supervisord.tar.gz" "etc.nginx.tar.gz" "etc.php7.tar.gz" "etc.my.cnf.d.tar.gz" "bin.tar.gz")

tar_pkgs_dir=("/var/ www" "/ sunlight" "/usr/local/ sunlight" "/var/lib/ mysql" "/usr/local/ acserver" "/etc/ cron.d" \
"/etc/ supervisord" "/etc/ nginx" "/etc/ php7" "/etc/ my.cnf.d" "/root/ bin")

file_pkgs=("/etc/keepalived/keepalived.conf" "/etc/supervisord.conf" "/etc/sysconfig/garb")



tar_pkgs_lenth=${#tar_pkgs[@]}
tar_pkgs_dir_length=${#tar_pkgs_dir[@]}
if [ $tar_pkgs_lenth -ne $tar_pkgs_dir_length ];then
	send_error "tar packages number is not equal to tar_pkgs_dir..."
	exit 1
fi

for ((i=0; i<$tar_pkgs_lenth; i++))
do
	sleep 1
	sunlight_backup_dir "${tar_pkgs[$i]}" "${tar_pkgs_dir[$i]}"
done

file_pkgs_length=${#file_pkgs[@]}
for ((i=0; i<$file_pkgs_length; i++))
do
	sleep 1
	sunlight_backup_file "${file_pkgs[$i]}"
done

sunlight_backup_mysql

echo "-----------------------------------------------"
send_info "directory and files backup finished...!"
send_info "backup dir: $backup_dir"