FROM ubuntu:latest

# This is in accordance to : https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04
RUN apt-get update && \
	apt-get install -y openjdk-8-jdk && \
	apt-get install -y ant && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/cache/oracle-jdk8-installer;
	
# Fix certificate issues, found as of 
# https://bugs.launchpad.net/ubuntu/+source/ca-certificates-java/+bug/983302
RUN apt-get install -y ca-certificates-java && \
	update-ca-certificates -f && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/cache/oracle-jdk8-installer;

RUN apt-get install -y wget tar bash && \
	apt-get clean 

# Setup JAVA_HOME, this is useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME
ENV PATH $JAVA_HOME/bin:$PATH

# Setup Python3 and its PIP
RUN apt-get install -y python3 python3-pip 
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Setup SSHD
USER root
EXPOSE 22/tcp
EXPOSE 22/udp

RUN apt-get install -y --no-install-recommends openssh-server vim

RUN echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config
RUN echo "Host *" >> /etc/ssh/ssh_config

# Download and setup Hadoop and Spark
EXPOSE 8081
EXPOSE 8080
EXPOSE 8088
EXPOSE 7077
EXPOSE 9870

RUN useradd -m -s /bin/bash hadoop

WORKDIR /home/hadoop

USER hadoop
RUN wget http://ftp.unicamp.br/pub/apache/hadoop/common/hadoop-3.2.0/hadoop-3.2.0.tar.gz
RUN tar -zxf hadoop-3.2.0.tar.gz && \
    ln -s hadoop-3.2.0 hadoop && \
	rm hadoop-3.2.0.tar.gz

RUN wget http://ftp.unicamp.br/pub/apache/spark/spark-2.4.3/spark-2.4.3-bin-without-hadoop.tgz
RUN tar -xzf spark-2.4.3-bin-without-hadoop.tgz && \
    ln -s spark-2.4.3-bin-without-hadoop spark && \
    rm spark-2.4.3-bin-without-hadoop.tgz

# Setup SSH for hadoop user
RUN mkdir /home/hadoop/.ssh
RUN mkdir /home/hadoop/hadoop/logs
RUN touch /home/hadoop/hadoop/logs/fairscheduler-statedump.log
RUN echo PubkeyAcceptedKeyTypes +ssh-dss >> /home/hadoop/.ssh/config
RUN echo PasswordAuthentication no >> /home/hadoop/.ssh/config

# Public and private keys for Hadoop user
COPY --chown=hadoop config/id_rsa config/id_rsa.pub /home/hadoop/.ssh/
RUN cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys


# Setup Hadoop own Environemt
RUN echo PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:$PATH >> /home/hadoop/.profile
RUN echo PATH=/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:$PATH >> /home/hadoop/.bashrc
RUN mkdir -p /home/hadoop/data/nameNode /home/hadoop/data/dataNode /home/hadoop/data/namesecondary /home/hadoop/data/tmp
RUN echo HADOOP_HOME=/home/hadoop/hadoop >> /home/hadoop/.bashrc
RUN echo JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/ >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_NAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo HDFS_DATANODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh                        
RUN echo HDFS_SECONDARYNAMENODE_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo YARN_RESOURCEMANAGER_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh
RUN echo YARN_NODEMANAGER_USER=hadoop >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh

# Setup Hadoop Spark Environemt
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.bashrc
RUN echo "export HADOOP_CONF_DIR=/home/hadoop/hadoop/etc/hadoop" >> /home/hadoop/.profile
RUN echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /home/hadoop/.bashrc
RUN echo "export SPARK_DIST_CLASSPATH=\$(hadoop classpath)" >> /home/hadoop/.profile
RUN echo "export SPARK_HOME=/home/hadoop/spark" >> /home/hadoop/.profile
RUN echo "export SPARK_HOME=/home/hadoop/spark" >> /home/hadoop/.bashrc
COPY --chown=hadoop config/sparkcmd.sh /home/hadoop/
COPY --chown=hadoop config/core-site.xml config/hdfs-site.xml config/mapred-site.xml config/yarn-site.xml /home/hadoop/hadoop/etc/hadoop/
#COPY --chown=hadoop config/workers /home/hadoop/hadoop/etc/hadoop/

USER root
#ENTRYPOINT ["/home/hadoop/sparkcmd.sh","start"]
RUN chmod +x /home/hadoop/*.sh
RUN chmod 600 /home/hadoop/.ssh/id_rsa
CMD service ssh start && sleep infinity
