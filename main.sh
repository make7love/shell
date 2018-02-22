#!/bin/bash

#sunlight sp monitor system 
#created on 2018/01/07
#by chao.dong
#used by sp servers consist of 1 manage server and 3 application servers
#此脚本用于shell公共类库；


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

export get_current_time_stamp
export send_error
export send_success
export send_info
export send_warn
