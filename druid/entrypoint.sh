#!/usr/bin/env bash
set -x

DRUID_NODE_TYPE=${1:-"coordinator"}
MEMORY=${JAVA_MEMORY:-"768m"}

echo "Using JVM heap size of $MEMORY for $DRUID_NODE_TYPE"

druid_config_alter(){
  sed -i "$1" /druid/config/$DRUID_NODE_TYPE/runtime.properties
}

druid_config_add(){
  echo -e "\n$1" >> /druid/config/$DRUID_NODE_TYPE/runtime.properties
}

if env | grep -q ZK_PORT_2181_TCP_ADDR; then
  druid_config_alter "s/druid.zk.service.host=localhost/druid.zk.service.host=$ZK_PORT_2181_TCP_ADDR/g"
  druid_config_add "druid.zk.paths.base=druid"
fi

if [ "$DRUID_NODE_TYPE" = "historical" ]; then
  if  env | grep -q s3_access_key && env | grep -q s3_secret_key; then
    druid_config_alter "s@druid.s3.secretKey.*@druid.s3.secretKey=$s3_secret_key@g"
    druid_config_alter "s@druid.s3.accessKey.*@druid.s3.accessKey=$s3_access_key@g"
    druid_config_add "druid.storage.bucket=$s3_bucket"
    druid_config_add "druid.storage.type=s3"
  fi
fi

setfattr -n user.pax.flags -v "mr" /usr/bin/java

druid_config_add "druid.processing.numThreads=1"
druid_config_add "druid.server.maxSize=10000000"
druid_config_add "druid.processing.buffer.sizeBytes=100000"

#if [ "$DRUID_NODE_TYPE" = "coordinator" ]; then
  #sleep 10
  #mysql -u root --password $MYSQL_ROOT_PASSWORD -h mysql -e "GRANT ALL ON druid.* TO 'druid'@'localhost' IDENTIFIED BY 'druid'; CREATE database druid CHARACTER SET utf8;"
  #java -Dfile.encoding=UTF-8 \
  #     -cp /druid/lib/*:/druid/config/$DRUID_NODE_TYPE \
  #     -Ddruid.metadata.storage.type=mysql \
  #     io.druid.cli.Main tools metadata-init --connectURI="jdbc:mysql://mysql:3306/druid" --user=druid --password=diurd
#fi

# Standardize port to 8000
druid_config_alter 's/druid.port=.*/druid.port=8000/g'

# Set specific hostname
druid_config_alter "s/druid.host=.*/druid.host=$IP/g"

cat /druid/config/$DRUID_NODE_TYPE/runtime.properties

sleep 5

java -server \
     -Xms$MEMORY \
     -Xmx$MEMORY \
     -XX:+UseG1GC \
     -XX:MaxDirectMemorySize=5g \
     -Duser.timezone=UTC \
     -Dfile.encoding=UTF-8 \
     -cp /druid/lib/*:/druid/config/$DRUID_NODE_TYPE \
     io.druid.cli.Main server $DRUID_NODE_TYPE
