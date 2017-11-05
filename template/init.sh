#!/usr/bin/env bash

service_name="pine"

exec="venv/bin/python venv/bin/gunicorn -c gun.py run:app"
work_dir=`pwd`

RETVAL=0

Red='\033[0;31m'
Color_Off='\033[0m'
Green='\033[0;32m'


do_status() {
    num=`ps aux|grep "${exec}"|grep -v "grep"|wc -l`
    if [ $num -ne 0 ];then
        last_pid=`ps aux|grep "${exec}"|grep -v "grep"|awk '{print $2}'|tail -n 1`
        pro_list=`ps aux|grep "${exec}"|grep -v "grep"|awk '{print $2}'|sed ':a;N;$!ba;s#\n#,#g'`
        start_time=`ps -p ${last_pid} -o lstart|grep -v 'STARTED'`
        t_count=`ps xH|grep ${last_pid}|grep -v grep|wc -l`
        p_count=`ps aux|grep "${exec}"|grep -v "grep"|awk '{print $2}'|wc -l`
        printf "${Green}         status: running${Color_Off}\n"
        printf "${Green}  process count: ${p_count}${Color_Off}\n"
        printf "${Green}threads/process: ${t_count}${Color_Off}\n"
        printf "${Green}   process list: ${pro_list}${Color_Off}\n"
        printf "${Green}         uptime: ${start_time}${Color_Off}\n"

    else
        printf "${Green}         status: stopped${Color_Off}\n"
    fi

    return $?
}

status() {
    do_status
    exit $?
}


do_start() {
    cd ${backend}
    num=`ps aux|grep "${exec}"|grep -v "grep"|wc -l`
    if [ $num -ne 0 ];then
        printf "${Red}${service_name} is running, Skipped try to start again.${Color_Off}\n"
        return 0
    fi
    $exec
    if [ $? -ne 0 ]; then
        printf "${Red}start ${service_name} occurred errors.${Color_Off}\n"
        return 1
    fi
    printf "${Green}start ${service_name} successfully.${Color_Off}\n"
    sleep 2
    do_status
    return $?
}

start() {
    do_start
    exit $?
}

do_build() {
    virtualenv --no-site-packages venv --python=python2.7
    venv/bin/pip install -r requirements.txt
    return $?
}

build() {
    do_build
    exit $?
}

do_stop() {
    num=`ps aux|grep "${exec}"|grep -v "grep"|wc -l`
    if [ $num -ne 0 ];then
       searching_pid=`ps aux|grep "${exec}"|grep -v "grep"|awk '{print $2}'`
       for p in $searching_pid
       do
          kill -9 $p
       done
    else
        printf "${Red}${service_name} is not running.${Color_Off}\n"
        return 0
    fi

    printf "${Green}shutdown ${service_name} successfully.${Color_Off}\n"
    return $?
}

stop() {
   do_stop
   exit $?
}


restart() {
    num=`ps aux|grep "${exec}"|grep -v "grep"|wc -l`
    if [ $num -eq 0 ];then
        printf "${Red}${service_name} is not running, Trying to start.${Color_Off}\n"
	do_start
	exit $?
    else
	do_stop
	if [ $? -ne 0 ];then
           printf "${Red} stop ${service_name} occurred errors.${Color_Off}\n"
	   exit 1
	else
	   do_start
	   exit $?
        fi
    fi
}


case "$1" in
    start)
    start
    ;;
    stop)
    stop
    ;;
    restart)
    restart
    ;;
    build)
    build
    ;;
    status)
    status
    ;;
    *)
    printf "${Red}Usage: service ${service_name} {start|stop|restart|status|build}.${Color_Off}\n"
        RETVAL=1
    esac
    exit $RETVAL
