#!/bin/bash
#这个脚本用来备份SQL文件；

sql_home="/home/mysql"
sql_bak_log="$sql_home/xtrabackup.log"
server_conf="/usr/local/sunlight/conf/server.conf"
sql_backup_date=$(date "+%Y%m%d")

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


if [ -z "$sql_user" ];then
	echo "Error! sql user is empty!"
	echo "Error! sql user is empty!" >> $sql_bak_log
	exit 1
fi

if [ -z "$sql_passwd" ];then
	echo "Error! sql password is empty!"
	echo "Error! sql password is empty!" >> $sql_bak_log
#	exit 1
fi

if [ ! -d $sql_home ];then
	mkdir -p $sql_home
	chown mysql:mysql $sql_home
	chmod 700 $sql_home
fi

#check mysql daemon
check_sql_daemon=$(mysql -h"$sql_host" -u"$sql_user" --password="$sql_passwd" -e "select version();")
if [ $? -ne 0 ];then
	echo "[ Error ] `date "+%Y/%m/%d %H:%M:%S"`  [ msg ] We didn't find mysql daemon!" 
	echo "[ Error ] `date "+%Y/%m/%d %H:%M:%S"`  [ msg ] We didn't find mysql daemon!" >> $sql_bak_log
	exit 1
fi

#check xtrabackup package
check_xtrabackup_rpm=$(rpm -qa|grep xtrabackup | wc -l)
if [ $check_xtrabackup_rpm -ne 1 ];then
	echo "[ Error ] `date "+%Y/%m/%d %H:%M:%S"`  [ msg ] xtrabackup does not be installed!" 
	echo "[ Error ] `date "+%Y/%m/%d %H:%M:%S"`  [ msg ] xtrabackup does not be installed!" >> $sql_bak_log
	exit 1
fi

if [ -e "$sql_home/${sql_backup_date}.tar.gz" ];then
	rm -f "$sql_home/${sql_backup_date}.tar.gz"
fi

sudo -u mysql innobackupex --user=$sql_user  --password="$sql_passwd"  --socket=/var/lib/mysql/mysql.sock --no-timestamp --stream=tar "$sql_home/" | gzip >  "$sql_home/${sql_backup_date}.tar.gz"

if [ $? -eq 0 ];then
	echo "[ Success ] `date "+%Y/%m/%d %H:%M:%S"`  [ msg ] The tar.gz package has been finished !" >> $sql_bak_log
else
	echo "[ Error ] `date "+%Y/%m/%d %H:%M:%S"`  [ msg ] The first backup step has been failed !" >> $sql_bak_log
	echo "-------------------------------------------------------------------------------------------------" >> $sql_bak_log
	exit 1
fi

chown mysql:mysql -R /home/mysql
chmod 755 -R /home/mysql

echo "[ Success ] `date "+%Y/%m/%d %H:%M:%S"`  Mysql Files Backup Success! " >>  $sql_bak_log
echo "-------------------------------------------------------------------------------------------------" >> $sql_bak_log
exit 0
