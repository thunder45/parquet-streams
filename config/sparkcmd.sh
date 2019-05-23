#!/bin/bash

if [[ $1 = "start" ]]; then
  if [[ $HOSTNAME = $SPARK_MASTER_NODE ]]; then
     /home/hadoop/spark/sbin/start-master.sh
     exit
  fi
  /home/hadoop/spark/sbin/start-slave.sh $SPARK_MASTER_NODE:$SPARK_MASTER_PORT
  exit
fi

if [[ $1 = "stop" ]]; then
  if [[ $HOSTNAME = $SPARK_MASTER_NODE ]]; then
     /home/hadoop/spark/sbin/stop-master.sh
     exit
  fi
  /home/hadoop/spark/sbin/stop-slave.sh
fi