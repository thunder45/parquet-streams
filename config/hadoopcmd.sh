#!/bin/bash

if [[ $1 = "start" ]]; then
  /home/hadoop/hadoop/sbin/start-dfs.sh
  sleep 5
  /home/hadoop/hadoop/sbin/start-yarn.sh
  exit
fi

if [[ $1 = "stop" ]]; then
  /home/hadoop/hadoop/sbin/stop-yarn.sh
  sleep 5
  /home/hadoop/hadoop/sbin/stop-dfs.sh
fi