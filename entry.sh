#!/bin/bash

/usr/sbin/sshd -D & 
su - hadoop -c "source .profile;/home/hadoop/hadoopcmd.sh start"
su - hadoop -c "source .profile;/home/hadoop/sparkcmd.sh start" 
sleep infinity 