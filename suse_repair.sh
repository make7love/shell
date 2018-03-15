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

if [ -e /sunlight/repair/finish ];then
	send_error "系统已经进行过修复，不能再次运行！"
	send_info "如有疑问，请联络：QQ472298551"
	exit 1
fi

repair_init

#1). add accounts
send_info "添加用户，避免账号共享；"
send_info "添加的用户为： sunlight 和 fsd"
send_info "添加的用户组：operator"
groupadd operator
useradd -g operator -d /home/fsd -m fsd
useradd -g operator -G wheel -d /home/sunlight -m sunlight
chmod 750 /home/*
send_success "账号添加成功！"
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

#4). 检查是否设置口令生存周期
send_info "检查是否设置口令生存周期是否<=90天"
if [ -f /etc/login.defs ];then
	cp /etc/login.defs  /sunlight/repair/
	sed -i '/^PASS_MAX_DAYS/c\PASS_MAX_DAYS	90'  /etc/login.defs
	if [ $? -eq 0 ];then
		send_success "口令生存周期 - 设置成功！"
	fi
	
	sed -i '/^PASS_MIN_DAYS/c\PASS_MIN_DAYS 6'  /etc/login.defs
	if [ $? -eq 0 ];then
	send_success "设置口令更改最小间隔天数- 设置成功！"
	fi
	
	sed -i '$a\PASS_MIN_LEN 6'  /etc/login.defs
	if [ $? -eq 0 ];then
		send_success "检查口令最小长度为6- 设置成功！"
	fi
else
	send_error "file /etc/login.defs not found..."
	exit 1
fi
sleep 2


#5). 配置用户最小授权
send_info "配置用户最小授权"
chmod 644 /etc/passwd
chmod 400 /etc/shadow
chmod 644 /etc/group
if [ $? -eq 0 ];then
	send_success "配置用户授权-设置成功！"
fi
sleep 2


#6). 文件与目录缺省权限控制；
send_info  "文件与目录缺省权限控制"
if [ $(egrep "^#umask" /etc/profile | wc -l) -eq 1 ];then
	cp /etc/profile  /sunlight/repair/
	sed -i '/^#umask/c\umask 027'  /etc/profile
else
	send_error "'umask' in /etc/profile not found..."
	exit 1
fi
if [ $? -eq 0 ];then
	send_success "缺省权限-设置成功！"
fi
sleep 2

#6). 限制root远程登录；
send_info "限制root远程登录"
cp /etc/ssh/sshd_config  /sunlight/repair/
if [ $(egrep "^#PermitRootLogin" /etc/ssh/sshd_config |wc -l) -eq 1 ];then
	sed -i '/^#PermitRootLogin/c\PermitRootLogin no'  /etc/ssh/sshd_config
elif [ $(egrep "^PermitRootLogin" /etc/ssh/sshd_config |wc -l) -eq 1 ];then
	sed -i '/^PermitRootLogin/c\PermitRootLogin no'  /etc/ssh/sshd_config
fi
if [ $? -eq 0 ];then
	send_success "禁止root远程登录-文件设置成功！"
fi
sleep 2

#7). 修改TMOUT值
send_info "设置超时时间"
cp /etc/profile  /sunlight/repair/
if [ $(grep "TMOUT" /etc/profile | wc -l) -eq 1 ];then
	sed -i '/TMOUT/c\export TMOUT=1200'
elif [ $(grep "TMOUT" /etc/profile | wc -l) -lt 1 ];then
	sed -i '$a\export TMOUT=1200'  /etc/profile
else
	send_error "/etc/profile 内的TMOUT值不能确定，请检查！"
	exit 1
fi
if [ $? -eq 0 ];then
	send_success "超时时间 - 设置成功！"
fi
sleep 2

#8). FTP服务设置；
send_info "关闭fpt服务"
send_info "ftp服务未开启..."
sleep 2

#9). 开启syslog日志审计功能
send_info "开启syslog日志审计功能"
if [ ! -f /var/log/secure ];then
	touch /var/log/secure
fi

if [ ! -f /etc/syslog.conf ];then
	touch /etc/syslog.conf
fi

cp /etc/syslog.conf  /sunlight/repair/
echo 'authpriv.*' >> /etc/syslog.conf

if [ ! -d /etc/syslog-ng ];then
	mkdir /etc/syslog-ng
fi
echo "filter f_secure { facility(authpriv); };" >> /etc/syslog-ng/syslog-ng.conf
echo "destination priverr { file(\"/var/log/secure\"); };" >> /etc/syslog-ng/syslog-ng.conf
echo "log { source(src); filter(f_secure); destination(priverr); };" >> /etc/syslog-ng/syslog-ng.conf
if [ $? -eq 0 ];then
	send_success "日志审计 - 设置成功！"
fi
sleep 2


#10). 记录cron行为日志功能；
send_info "设置记录cron行为日志"
if [ ! -f /etc/syslog.conf ];then
	touch /etc/syslog.conf
fi

if [ ! -f /var/log/cron ];then
	touch /var/log/cron
	chmod 666 /var/log/cron
fi

if [ $(grep "cron"  /etc/syslog.conf | wc -l) -lt 1 ];then
	echo "cron.* /var/log/cron" >>  /etc/syslog.conf
fi
if [ $? -eq 0 ];then
	send_success "cron行为日志 - 设置成功！"
fi
sleep 2


#11). 启用远程日志功能；
send_info "启用远程日志功能"
if [ ! -f /etc/syslog.conf ];then
	touch /etc/syslog.conf
fi
echo "kern.* ; mail.*"@192.168.88.1 >> /etc/syslog.conf
if [ $? -eq 0 ];then
	send_success "远程日志功能 - 设置成功！"
fi
sleep 2

#12). 设置系统banner
if [ -f /etc/issue ];then
	mv /etc/issue  /etc/issue.bak
fi

if [ -f /etc/issue.net ];then
	mv /etc/issue.net /etc/issue.net.bak
fi
if [ $? -eq 0 ];then
	send_success "系统banner - 设置成功！"
fi
sleep 2


#13).删除潜在危险文件
send_info "移除潜在危险文件"
if [ -f /etc/hosts.equiv ];then
	mv /etc/hosts.equiv   /etc/hosts.equiv.bak
fi

if [ -f /etc/.netrc ];then
	mv /etc/.netrc   /etc/.netrc.bak
fi

if [ -f /etc/.rhosts ];then
	mv /etc/.rhosts   /etc/.rhosts.bak
fi

if [ $? -eq 0 ];then
	send_success "潜在危险文件 - 移除成功！"
fi




#14）检查系统core dump设置
if [ -f /etc/security/limits.conf ];then
	cp /etc/security/limits.conf  /sunlight/repair/
	if [ $(grep "hard core" /etc/security/limits.conf | wc -l) -gt 0 ];then
		sed -i '/hard core/d' /etc/security/limits.conf
	fi
	sed -i '$a\* hard core 0' /etc/security/limits.conf 
	if [ $? -eq 0 ];then
		send_success "hard core 设置成功！"
	fi
	
	if [ $(grep "soft core" /etc/security/limits.conf | wc -l) -gt 0 ];then
		sed -i '/soft core/d' /etc/security/limits.conf
	fi
	sed -i '$a\* soft core 0' /etc/security/limits.conf
	if [ $? -eq 0 ];then
		send_success "soft core 设置成功！"
	fi
else
	send_error "/etc/security/limits.conf not found...!"
fi


#15). 检查历史命令设置；
if [ $(egrep "^HISTFILESIZE" /etc/profile | wc -l) -eq 1 ];then
	sed -i '/^HISTFILESIZE/c\HISTFILESIZE=5' /etc/profile
else
	sed -i '$a\HISTFILESIZE=5' /etc/profile
fi
if [ $? -eq 0 ];then
	send_success "保留历史命令条数：5"
fi

#16). 检查密码重复使用次数限制
sed -i '$a\password sufficient pam_unix.so md5 shadow nullok try_first_pass use_authtok remember=5'

touch /sunlight/repair/finish
echo "----------------修复完成----------------"
exit 0