# Debug TPCDS query plans on spark

### Debug simple spark scenarios
In general debugging spark driver is straight forward. 
1. Simply clone the [source](https://github.com/apache/spark.git) and build. 
2. On the shell ```export SPARK_SUBMIT_OPTS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=4000```
3. Launch spark-shell
4. Launch IntelliJ and attach to local process on port number mentioned above i.e 4000
5. Put break points in appropriate places and have fun debugging and exploring.

### Debug 1TB dataset
When debugging locally for cost based optimizer internals and query plans, we can point a local build of spark to a remote store and metastore which contains a very large dataset (e.g 1TB tpcds dataset). I am using an Azure blob storage based storage backend and sql server based metastore. Its easy to port the solution to use any combination of storage backend(e.g hdfs/s3) and metastore(mysql, etc). 
 
1. Debug on your box
   - Follow the steps in the Dockerfile to setup the environment.
   - Use the debugging instructions above to setup Intellij and have fun.
2. Debug using a docker container
   - Build the docker file using ```sudo docker build -t <imageName> 
    --build-arg CONTAINER=<a container in azure blob storage>
    --build-arg STORAGEACCOUNT=<an Azure blob storage account name>
    --build-arg STORAGEKEY=<key to the storage account>
    --build-arg DBSERVER=<metastore db server name>
    --build-arg DB=<database name>
    --build-arg USER=<user name for the db>
    --build-arg PASS=<password for the user> .```
   - sudo docker run --hostname doc -p 40000:4000 -it spark /bin/bash
   - Verify setup by running ```$HADOOP_HOME/bin/hdfs dfs -ls /```
   - Run $SPARK_HOME/bin/spark-shell
   - Launch IntelliJ and setup a Debug configuration Run -> Edit Configurations -> + -> Remote -> Change port to 40000 -> Apply
   - Get a local copy of spark
   - Start debugging
