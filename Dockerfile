FROM openjdk:8-alpine

# Setup SSH, wget, tar, bash, Python3 and its PIP
RUN apk update && apk upgrade && \
    apk add --no-cache wget tar bash net-tools python3 openssh vim coreutils procps && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    /usr/bin/ssh-keygen -A && \
    sed -i "s/#PermitRootLogin.*/PermitRootLogin without-password/" /etc/ssh/sshd_config && \
    sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config  && \
    echo "Host *" >> /etc/ssh/ssh_config && \
    mkdir -p /var/run/sshd && \
    rm -rf /var/cache/apk/*

EXPOSE 22/tcp
EXPOSE 22/udp

# Spark Workers
EXPOSE 8081 4040

# Spark Master
EXPOSE 8080 7077

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

# Create a group and user
RUN addgroup hadoop && adduser -D hadoop -G hadoop -s /bin/bash && \
    sed -i "/hadoop\:\!/s/\!/\*/g" /etc/shadow

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

# SSH Key Passwordless
RUN mkdir -p /home/hadoop/.ssh && \
    ssh-keygen -t rsa -P '' -f /home/hadoop/.ssh/id_rsa && \
    echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config && \
    echo PasswordAuthentication no >> /home/hadoop/.ssh/config && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chmod 700 /home/hadoop/.ssh && \
    chmod 600 /home/hadoop/.ssh/config && \
    chmod 600 /home/hadoop/.ssh/id_rsa && \
    chmod 600 /home/hadoop/.ssh/authorized_keys

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

COPY --chown=hadoop config/sparkcmd.sh config/hadoopcmd.sh entry.sh /home/hadoop/
COPY --chown=hadoop config/workers config/core-site.xml config/hdfs-site.xml config/mapred-site.xml config/yarn-site.xml /home/hadoop/hadoop/etc/hadoop/

USER root
CMD /home/hadoop/entry.sh
