#!/bin/bash
#by chao.dong
#472298551@qq.com
#亚特兰蒂斯项目
#用于单独还原epg/sunboss

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

if [ $# -ne 2 ];then
	send_error "输入参数错误！"
	send_error "parameter passed error!"
	exit 1
fi

data_dir=$1
data_type=$2
project_dir="/var/www/html"


if [ ! -d "$data_dir" ];then
	send_error "请输入正确的数据备份目录！"
	send_error "Please provide correct data backup directory!"
	exit 1
fi

if [ "$data_type" != "epg" && "$data_type" != "sunboss" && "$data_type" != "www" ];then
	send_error "还原指令错误！"
	send_error "restore parameter is not correct!"
	send_error "---- It must be 'epg', 'sunboss' or 'www' ----"
	exit 1
fi


if [ ${data_dir:0:1} != "/" ];then
	send_error "$1 must start with /"
	send_info "请输入绝对路径，以/开头..."
	exit 1
fi

if [[ -d $data_dir && ${data_dir:0-1:1} != "/" ]];then
	data_dir="$data_dir/"
fi


if [ ! -e "${data_dir}www.tar.gz" ];then
	send_error "${data_dir}www.tar.gz not found..."
	send_error "${data_dir}www.tar.gz  文件不存在！请检查！"
	exit 1
fi

if [ ! -d $project_dir ];then
	send_error "$project_dir not found..."
	exit 1
fi

function restore_epg()
{
	
}

function restore_sunboss()
{
	send_info "开始还原sunboss..."
	sleep 2
	send_info "首先移动原有/var/www目录..."
	send_info "mv /var/www  /tmp/restore/`date "+%Y%m%d"`"
	
	if [ ! -d /tmp/restore/`date "+%Y%m%d"` ];then
		mkdir -p /tmp/restore/`date "+%Y%m%d"`
		chmod 755 /tmp/restore/`date "+%Y%m%d"`
	fi
	if [ $? -eq 0 ];then
		send_success "创建临时目录成功！"
		send_success "/tmp/restore/`date "+%Y%m%d"`  create success!"
	else
		send_error "/tmp/restore/`date "+%Y%m%d"`  create failed!"
		exit 1
	fi
	
	mv  /var/www  /tmp/restore/`date "+%Y%m%d"`/
	tar -zxvf "${data_dir}www.tar.gz" -C /var/
	
}

function restore_www()
{

}


if [ $data_type == "sunboss" ];then
	restore_sunboss
elif [ $data_type == "www" ];then
	restore_www
else
	restore_epg
fi





