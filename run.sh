#!/bin/bash

######################################
#  SCRIPT: run.sh
#  Description: Used to handle nginx container
######################################

set -e
#set -x

cd $(dirname $0)

COMMAND="${1:-help}"
CONF=${2}

uid=$(id -u)
uname=$(id -un)
gid=$(id -g)
gname=$(id -gn)

if ! [ -x "$(command -v docker)" ]; then
  echo -e "INFO: Docker installation not found"
  exit 1
fi



usage() {
  echo -e "\nUsage: run.sh start|stop|help\n"
  echo -e "\tstart CONF                Start nginx container"
  echo -e "\tstop CONF                 Stop nginx container"
  echo -e "\trestart CONF              Stop and startnginx container"
  echo -e "\thelp                      Show usage"
  exit 0
}

check_conf() {
  echo -e "\nCheck whether ./conf/conf.d/${CONF}.conf file exist"
  echo -e "------------------------------------------------------------"

  if [ ! -f "./conf/conf.d/${CONF}.conf" ]; then
    echo "./conf/conf.d/${CONF}.conf file does not exist"
    exit 1
  fi
}

make_dir() {
  if ! [ -d "./logs" ]; then
    echo -e "\nMake ./logs dir owned by uid=${uid}(${uname}), gid=${gid}(${gname})"
    echo -e "----------------------------------------------------------------"

    mkdir ./logs
  fi
}

make_initsh() {
  echo -e "\nMake ./init_script/init.sh from ./init_script/init.sh.template"
  echo -e "----------------------------------------------------------------"

  export uid uname gid gname
  envsubst < ./init_script/init.sh.template > ./init_script/init.sh
  chmod u+x ./init_script/init.sh
}

case "$COMMAND" in

  start)
    # check whether ./conf/conf.d/${CONF}.conf file exist
    check_conf
    # make ./logs directory for nginx container bind mount
    make_dir
    # make init.sh from ./init_script/init.sh.template
    make_initsh

    echo -e "\nStart nginx container (CONF=${CONF})"
    echo -e "Worker process owned by uid=${uid}(${uname}), gid=${gid}(${gname})"
    echo -e "----------------------------------------------------------------"
    
    export CONF; docker compose up -d

    exit 0
    ;;

  stop)
    # check whether ./conf/conf.d/${CONF}.conf file exist
    check_conf

    echo -e "\nStop nginx container (CONF=${CONF})"
    echo -e "----------------------------------------------------------------"

    export CONF; docker compose down -v
    exit 0
    ;;

  restart)
    ./run.sh stop ${CONF}
    ./run.sh start ${CONF}

    exit 0
    ;;

  help|*)
    usage

    exit 0
    ;;

esac

\e[1;32m [OK] \e[0;39m