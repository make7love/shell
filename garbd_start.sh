#!/bin/bash

#用于启动garbd服务，并加入supervisord；


data_o="10.108.144.1:4567"
data_t="10.108.144.2:4567"


if [ ! -d /var/log/garb ];then
	mkdir /var/log/garb
	chmod 755 /var/log/garb
fi

nohup /usr/bin/garbd -a gcomm://$data_o,$data_t -g sunlight_stb_cluster -l /var/log/garb/garbd.log &
