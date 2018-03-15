#!/bin/bash
#说明：
#此脚本主要应对电信、绿盟扫描对操作系统提出的安全规范；
#适用的操作系统： SUSE 12 sp2
#by chao.dong
#472298551@qq.com
#2018-02-21

function get_current_time_stamp()
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

function repair_init()
{
	if [ ! -d /sunlight/repair ];then
		mkdir -p /sunlight/repair
		chmod 750 /sunlight/repair
	fi
}

if [ $(cat /etc/issue | grep "SUSE Linux Enterprise Server 12 SP2" | wc -l) -ne 1 ];then
	send_error "This shell script only fits SUSE Linux Enterprise Server 12 SP2!"
	exit 1
fi

if [ ! -d /sunlight/repair ];then
	mkdir -p /sunlight/repair
	chmod 750 /sunlight/repair
fi

echo "添加operator用户组..."
if [ $(grep operator /etc/groups | wc -l) -lt 1 ];then
	groupadd operator
	if [ $? -eq 0 ];then
		send_success "group 'operator' add finished..."
	fi
else
	send_info "group name operator found, skip..."
fi

if [ $(grep fsd /etc/passwd | wc -l) -lt 1 ];then
	useradd -g operator -G wheel -d /home/fsd  -m fsd
	if [ $? -eq 0 ];then
		send_success "user fsd add finished..."
	fi
else
	send_info "user fsd found, skip..."
fi


if [ $(grep sunlight /etc/passwd | wc -l) -lt 1 ];then
	useradd -g operator -G wheel -d /home/sunlight  -m sunlight
	if [ $? -eq 0 ];then
		send_success "user sunlight add finished..."
	fi
else
	send_info "user sunlight found, skip..."
fi
sleep 2


#2). 限制特定用户su到root
send_info "限制特定用户su到root"
if [ -f /etc/pam.d/su ];then
	cp /etc/pam.d/su  /sunlight/repair/
	if [ $(egrep "auth[ ]*sufficient[ ]*pam_rootok.so" /etc/pam.d/su | wc -l) -ne 1 ];then
		sed -i "1a\auth sufficient pam_rootok.so" /etc/pam.d/su
	else
		send_info "pam_rootok  set found...skip!"
	fi
	if [ $(egrep "auth[ ]*required[ ]*pam_wheel.so[ ]*group=wheel" /etc/pam.d/su | wc -l) -ne 1 ];then
		sed -i '/auth[ ]*sufficient[ ]*pam_rootok.so$/a\auth required pam_wheel.so group=wheel' /etc/pam.d/su
	else
		send_info "limit user su to root set found...skip!"
	fi
	if [ $? -eq 0 ];then
		send_success "特定用户su到root - 设置成功！"
	fi
	sleep 2
else
	send_error "file  /etc/pam.d/su not found..."
	exit 1
fi

#3).设置密码复杂度和优先级
send_info "设置密码复杂度和优先级..."
send_info "设置密码长度为8, 包含大小写字母和数字..."
if [ -f /etc/pam.d/common-password ];then
	cp /etc/pam.d/common-password  /sunlight/repair/
	sed -i '/password\trequisite\tpam_cracklib.so/c\password\trequisite\tpam_cracklib.so\t  minlen=8\tucredit=-1\tlcredit=-1\tdcredit=-1' /etc/pam.d/common-password
	if [ $? -eq 0 ];then
		send_success "密码复杂度 - 设置成功！"
	fi
else
	send_error "file /etc/pam.d/common-password not found..."
	exit 1
fi
sleep 2
	