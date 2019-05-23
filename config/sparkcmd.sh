#!/bin/bash

service ssh start

export USER=hadoop
source .profile

/home/hadoop/hadoop/sbin/start-dfs.sh
sleep 5
/home/hadoop/hadoop/sbin/start-yarn.sh
sleep 5
if [[ $1 = "start" ]]; then
  if [[ $HOSTNAME = $SPARK_MASTER_NODE ]]; then
     /home/hadoop/spark/sbin/start-master.sh
     sleep infinity
     exit
  fi
  /home/hadoop/spark/sbin/start-slave.sh $SPARK_MASTER
  sleep infinity
  exit
fi

if [[ $1 = "stop" ]]; then
  if [[ $HOSTNAME = $SPARK_MASTER_NODE ]]; then
     /home/hadoop/spark/sbin/stop-master.sh
     exit
  fi
  /home/hadoop/spark/sbin/stop-slave.sh
fi