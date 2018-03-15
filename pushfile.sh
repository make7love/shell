#!/bin/bash

apps=("192.168.0.96" "192.168.0.98" "192.168.0.168")

if [ $# -lt 1 ];then
	echo " [ Error ] The paramters passed to this shell is empty!"
	exit 1
fi

if [[ ! -d $1 && ! -f $1 ]];then
	echo " [ Error ] $1 does not exist!"
	exit 1
fi

params=$1

if [ ${params:0:1} != "/" ];then
	echo " [ Error ] $1 must start with /"
	exit 1
fi

if [[ -d $params && ${params:0-1:1} != "/" ]];then
	params="$params/"
fi

for app in ${apps[@]}
do
	if [ -d $params ];then
		ssh -p2222 -i /usr/local/sunlight/sshkeys/init.pk -o strictHostKeyChecking=no $app  "test -d  $params || mkdir -p $params"
	fi
	if [ -f $params ];then
		param_dir=${params%/*}
		ssh -p2222 -i /usr/local/sunlight/sshkeys/init.pk -o strictHostKeyChecking=no $app  "test -d  $param_dir || mkdir -p $param_dir"
	fi
	echo "rsync $app............"
	rsync -avztog --delete --progress -e "ssh -p2222 -i /usr/local/sunlight/sshkeys/init.pk -o strictHostKeyChecking=no" ${params} ${app}:${params}
done
