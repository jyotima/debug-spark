FROM ubuntu:16.04

ENV HADOOP_HOME /hadoop-2.7.3
ENV HADOOP_CLASSPATH $HADOOP_HOME/share/hadoop/tools/lib/*
ENV SPARK_HOME /spark
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN apt-get update \
    && apt-get install -y wget \
    && apt-get install -y git \
    && apt-get install -y openjdk-8-jdk

# Set up hadoop
RUN wget https://archive.apache.org/dist/hadoop/core/hadoop-2.7.3/hadoop-2.7.3.tar.gz 
RUN tar -xvzf /hadoop-2.7.3.tar.gz

COPY ./jetty-util-6.1.25.jar $HADOOP_HOME/share/hadoop/tools/lib/
COPY ./sqljdbc42.jar $HADOOP_HOME/share/hadoop/tools/lib/
COPY ./core-site.xml $HADOOP_HOME/etc/hadoop/

# Set up spark
RUN git clone https://github.com/apache/spark.git $SPARK_HOME \
    && cd $SPARK_HOME \
    && git checkout -b 2.3.1 v2.3.1
RUN cd $SPARK_HOME && ./build/mvn -DskipTests clean package -Phive -Phive-thriftserver -Phadoop-2.7 -Dhadoop.version=2.7.3

ENV SPARK_DIST_CLASSPATH $HADOOP_HOME/etc/hadoop:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs:$HADOOP_HOME/share/hadoop/hdfs/lib/*:HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar:$HADOOP_HOME/share/hadoop/tools/lib/*
COPY ./hive-site.xml $SPARK_HOME/conf/

ENV DRIVER_EXTRA_JAVA_OPTIONS spark.driver.extraJavaOptions\ -Djavax.xml.parsers.SAXParserFactory=com.sun.org.apache.xerces.internal.jaxp.SAXParserFactoryImpl\ -Dlog4j.configuration=file:///$SPARK_HOME/conf/log4j.driver.properties

RUN cp $SPARK_HOME/conf/spark-defaults.conf.template /$SPARK_HOME/conf/spark-defaults.conf

RUN echo "spark.executor.extraJavaOptions -Djavax.xml.parsers.SAXParserFactory=com.sun.org.apache.xerces.internal.jaxp.SAXParserFactoryImpl" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo $DRIVER_EXTRA_JAVA_OPTIONS >> $SPARK_HOME/conf/spark-defaults.conf
COPY ./log4j.driver.properties $SPARK_HOME/conf

# Set up hdfs storage and sql metastore
ARG CONTAINER=container
ARG STORAGEKEY=storagekey
ARG STORAGEACCOUNT=storageaccount
ARG DBSERVER=databaseservername
ARG DB=databasename
ARG USER=connectionusername
ARG PASS=connectionpassword

RUN sed -i s/container/$CONTAINER/g $HADOOP_HOME/etc/hadoop/core-site.xml
RUN sed -i s/storageaccount/$STORAGEACCOUNT/g $HADOOP_HOME/etc/hadoop/core-site.xml
RUN sed -i s/storagekey/$STORAGEKEY/g $HADOOP_HOME/etc/hadoop/core-site.xml
RUN sed -i s/databaseservername/$DBSERVER/g $SPARK_HOME/conf/hive-site.xml
RUN sed -i s/databasename/$DB/g $SPARK_HOME/conf/hive-site.xml
RUN sed -i s/connectionusername/$USER/g $SPARK_HOME/conf/hive-site.xml
RUN sed -i s/connectionpassword/$PASS/g $SPARK_HOME/conf/hive-site.xml

ENV SPARK_SUBMIT_OPTS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=4000
EXPOSE 4000/udp
EXPOSE 4000/tcp
