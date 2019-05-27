FROM openjdk:8-alpine

# This is in accordance to : https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04
# Fix certificate issues, found as of 
# https://bugs.launchpad.net/ubuntu/+source/ca-certificates-java/+bug/983302
# RUN apt-get update && \
# 	apt-get install -y openjdk-8-jdk && \
# 	apt-get install -y ant && \
#     apt-get install -y ca-certificates-java && \
# 	update-ca-certificates -f && \
# 	rm -rf /var/lib/apt/lists/* && \
# 	rm -rf /var/cache/oracle-jdk8-installer;

# Setup JAVA_HOME, this is useful for docker commandline
# ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
# RUN export JAVA_HOME
# ENV PATH $JAVA_HOME/bin:$PATH

# Setup SSH, wget, tar, bash, Python3 and its PIP
RUN apk update && apk upgrade && \
    apk add --no-cache wget tar bash net-tools python3 openssh vim && \
    /usr/bin/ssh-keygen -A && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config  && \
    echo "Host *" >> /etc/ssh/ssh_config && \
    rm -rf /var/cache/apk/*

# ssh-keygen -q -N "" -t rsa -f /etc/ssh/id_rsa && \
# cp /etc/ssh/id_rsa.pub /etc/ssh/authorized_keys && \

# RUN sed -i '/StrictHostKeyChecking/s/ask/no/g' /etc/ssh/ssh_config \
#     && sed -i '/StrictHostKeyChecking/s/#//g' /etc/ssh/ssh_config

EXPOSE 22/tcp
EXPOSE 22/udp

# Spark Workers
EXPOSE 8081
EXPOSE 4040

# Spark Master
EXPOSE 8080
EXPOSE 7077

# Hadoop
EXPOSE 9870

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000

 # Mapred ports
EXPOSE 10020 19888

 # Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088

# This is for Jupyter, just in case
EXPOSE 8888

#RUN useradd -m -s /bin/bash hadoop
# Create a group and user
RUN addgroup hadoop && adduser -D hadoop -G hadoop -s /bin/bash

WORKDIR /home/hadoop
ENV HADOOP_VERSION 3.2.0
ENV SPARK_VERSION 2.4.3

USER hadoop
RUN wget --quiet http://ftp.unicamp.br/pub/apache/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -zxf hadoop-${HADOOP_VERSION}.tar.gz && \
    ln -s hadoop-${HADOOP_VERSION} hadoop && \
    rm hadoop-${HADOOP_VERSION}.tar.gz && \
    rm -fR hadoop-${HADOOP_VERSION}/share/doc \
            hadoop-${HADOOP_VERSION}/share/hadoop/common/jdiff && \
    wget --quiet http://ftp.unicamp.br/pub/apache/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-without-hadoop.tgz && \
    ln -s spark-${SPARK_VERSION}-bin-without-hadoop spark && \
    rm spark-${SPARK_VERSION}-bin-without-hadoop.tgz

# Setup SSH for hadoop user
# Public and private keys for Hadoop user
#COPY --chown=hadoop config/id_rsa config/id_rsa.pub /home/hadoop/.ssh/
# RUN echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config && \
#     echo PasswordAuthentication no >> /home/hadoop/.ssh/config && \
# 	cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys

# SSH Key Passwordless
RUN mkdir -p /home/hadoop/.ssh && \
    ssh-keygen -t rsa -P '' -f /home/hadoop/.ssh/id_rsa && \
    echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config && \
    echo PasswordAuthentication no >> /home/hadoop/.ssh/config && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chmod 755 /home/hadoop/.ssh && \
    chmod 644 /home/hadoop/.ssh/config && \
    chmod 600 /home/hadoop/.ssh/id_rsa && \
    chmod 644 /home/hadoop/.ssh/authorized_keys

# Setup Hadoop own Environemt and fix path for both Hadoop and Spark
RUN mkdir /home/hadoop/hadoop/logs && \
    touch /home/hadoop/hadoop/logs/fairscheduler-statedump.log && \
    mkdir -p /home/hadoop/data/nameNode /home/hadoop/data/dataNode /home/hadoop/data/namesecondary /home/hadoop/data/tmp && \
    echo "export HADOOP_HOME=/home/hadoop/hadoop" >> /home/hadoop/.bashrc && \
    echo "export HADOOP_HOME=/home/hadoop/hadoop" >> /home/hadoop/.profile && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /home/hadoop/.bashrc && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /home/hadoop/.profile && \
    echo JAVA_HOME=$JAVA_HOME >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \
    echo HDFS_NAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \
    echo HDFS_DATANODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \                        
    echo HDFS_SECONDARYNAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \
    echo YARN_RESOURCEMANAGER_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \
    echo YARN_NODEMANAGER_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \
    echo PATH=/home/hadoop/spark/bin:/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:$PATH >> /home/hadoop/.profile && \
    echo PATH=/home/hadoop/spark/bin:/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:$PATH >> /home/hadoop/.bashrc && \
    echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.bashrc && \
    echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.profile && \
    echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /home/hadoop/.bashrc && \
    echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /home/hadoop/.profile && \
    echo "export SPARK_HOME=/home/hadoop/spark" >> /home/hadoop/.profile && \
    echo "export SPARK_HOME=/home/hadoop/spark" >> /home/hadoop/.bashrc && \
    echo "export SPARK_MASTER_NODE=spark-master" >> /home/hadoop/.profile && \
    echo "export SPARK_MASTER_NODE=spark-master" >> /home/hadoop/.bashrc && \
    echo "export SPARK_MASTER_PORT=7077" >> /home/hadoop/.profile && \
    echo "export SPARK_MASTER_PORT=7077" >> /home/hadoop/.bashrc && \
    echo "export SPARK_MASTER_FQDN=spark://spark-master:7077" >> /home/hadoop/.profile && \
    echo "export SPARK_MASTER_FQDN=spark://spark-master:7077" >> /home/hadoop/.bashrc && \
    echo "export SPARK_MASTER_WEBUI_PORT=8080" >> /home/hadoop/.profile && \
    echo "export SPARK_MASTER_WEBUI_PORT=8080" >> /home/hadoop/.bashrc

COPY --chown=hadoop config/sparkcmd.sh config/hadoopcmd.sh /home/hadoop/
COPY --chown=hadoop config/workers config/core-site.xml config/hdfs-site.xml config/mapred-site.xml config/yarn-site.xml /home/hadoop/hadoop/etc/hadoop/

USER root
# RUN chmod +x /home/hadoop/*.sh && \
#     chmod 600 /etc/ssh/id_rsa && \
#     chmod 600 /etc/ssh/authorized_keys 
CMD exec /usr/sbin/sshd -D & && \
    su - hadoop -c "/home/hadoop/hadoopcmd.sh start" && \
    su - hadoop -c "/home/hadoop/sparkcmd.sh start" && \
    sleep infinity
