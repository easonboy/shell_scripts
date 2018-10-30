#!/bin/bash

#远程服务器目录，如果不存在，需要创建

APP_DIR=/usr/local/src/WAR_backup   
IP='192.168.1.37'

#打包,将包推送到对应服务器上
function MVN_SCP(){
cd $WORKSPACE
mvn clean install -P dev -Dmaven.test.skip=true 
scp  $WORKSPACE/target/ROOT.war root@$IP:$APP_DIR/

[ $? -ne 0 ] && echo -e 'Failed to scp the ROOT.war'

}


 
function deploy()
{
echo "MVN & SCP"
  MVN_SCP
  sleep 10
ssh root@$IP  "echo "调用部署" && /usr/local/sbin/shell/deploy.sh $mode"
}
 
 
function rollback()
{
ssh root@$IP "echo "调用部署" && /usr/local/sbin/shell/deploy.sh $mode"
}
 

case $mode in
 deploy)
        deploy
        ;;
 rollback)
        rollback
        ;;
 *)
        echo $"Usage: $0 {deploy|rollback}"
        exit 1
        ;;
esac
