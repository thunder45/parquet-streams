FROM ubuntu:latest

# This is in accordance to : https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04
# Fix certificate issues, found as of 
# https://bugs.launchpad.net/ubuntu/+source/ca-certificates-java/+bug/983302
RUN apt-get update && \
	apt-get install -y openjdk-8-jdk && \
	apt-get install -y ant && \
    apt-get install -y ca-certificates-java && \
	update-ca-certificates -f && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/cache/oracle-jdk8-installer;

# Setup JAVA_HOME, this is useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
RUN export JAVA_HOME
ENV PATH $JAVA_HOME/bin:$PATH

# Setup SSH, wget, tar, bash, Python3 and its PIP
RUN apt-get update && \
    apt-get install -y wget tar bash netcat net-tools && \
	apt-get install -y python3 python3-pip && \
	apt-get install -y --no-install-recommends openssh-server vim && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config  && \
    echo "Host *" >> /etc/ssh/ssh_config && \
	update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 &&\
	apt-get clean
	
EXPOSE 22/tcp
EXPOSE 22/udp

# Spark Workers
EXPOSE 8081
EXPOSE 4040

# Spark Master
EXPOSE 8080
EXPOSE 7077

# Hadoop
EXPOSE 8088
EXPOSE 9870
EXPOSE 9000

# This is for Jupyter, just in case
EXPOSE 8888

RUN useradd -m -s /bin/bash hadoop

WORKDIR /home/hadoop

USER hadoop
RUN wget http://ftp.unicamp.br/pub/apache/hadoop/common/hadoop-3.2.0/hadoop-3.2.0.tar.gz && \
    tar -zxf hadoop-3.2.0.tar.gz && \
    ln -s hadoop-3.2.0 hadoop && \
	rm hadoop-3.2.0.tar.gz && \
    wget http://ftp.unicamp.br/pub/apache/spark/spark-2.4.3/spark-2.4.3-bin-without-hadoop.tgz && \
	tar -xzf spark-2.4.3-bin-without-hadoop.tgz && \
    ln -s spark-2.4.3-bin-without-hadoop spark && \
    rm spark-2.4.3-bin-without-hadoop.tgz

# Setup SSH for hadoop user
# Public and private keys for Hadoop user
COPY --chown=hadoop config/id_rsa config/id_rsa.pub /home/hadoop/.ssh/
RUN  echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config && \
    echo PasswordAuthentication no >> /home/hadoop/.ssh/config && \
	cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys

# Setup Hadoop own Environemt and fix path for both Hadoop and Spark
RUN mkdir /home/hadoop/hadoop/logs && \
    touch /home/hadoop/hadoop/logs/fairscheduler-statedump.log && \
    mkdir -p /home/hadoop/data/nameNode /home/hadoop/data/dataNode /home/hadoop/data/namesecondary /home/hadoop/data/tmp && \
    echo "export HADOOP_HOME=/home/hadoop/hadoop" >> /home/hadoop/.bashrc && \
    echo "export HADOOP_HOME=/home/hadoop/hadoop" >> /home/hadoop/.profile && \
	echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /home/hadoop/.bashrc && \
	echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /home/hadoop/.profile && \
    echo JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh && \
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
RUN chmod +x /home/hadoop/*.sh && \
	chmod 600 /home/hadoop/.ssh/id_rsa
CMD service ssh start && \
    su - hadoop -c "/home/hadoop/hadoopcmd.sh start" && \
	su - hadoop -c "/home/hadoop/sparkcmd.sh start" && \
	sleep infinity
