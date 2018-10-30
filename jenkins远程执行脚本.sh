#!/bin/bash
source /etc/profile

bak_dir=/usr/local/src/WAR_backup/
date=$(date +"%Y%m%d%H%M%S")
nginx=/usr/local/nginx/sbin/nginx
nginx_conf=/usr/local/nginx/conf/extra/upstream.conf

function tomcat_deploy()
{
    #echo $1
    /etc/init.d/$1 stop || ps -ef|grep $1|grep -v 'grep'|xargs kill -9
    sleep 5
    cd /usr/local/apache-$1/webapps/
    #多备份一份
    cp ROOT.war $bak_dir/ROOT_$(date +"%y%m%d%H%M%S").war
    mv ROOT.war ROOT.wa && rm -rf ROOT
    cp  $bak_dir/ROOT.war  /usr/local/apache-$1/webapps/ROOT.war
    /etc/init.d/$1 start
    sleep 10

}

function tomcat_rollback()
{
    ps -ef|grep $1|grep -v 'grep'|awk '{print $2}'|xargs kill -9
    cd /usr/local/apache-$1/webapps/
    rm -f ROOT.war && rm -rf ROOT
    mv ROOT.wa  ROOT.war
    /etc/init.d/$1 start
    sleep 10

}

deploy(){
    ##将tomcat1从池子中下掉
    echo "stop_apache-tomcat1"
    sed -i 's#server 127.0.0.1:8081;#server 127.0.0.1:8081 down;#' $nginx_conf && nginx -s reload
    echo 'start deploy tomcat1 node'

    tomcat_deploy tomcat1

    #将tocmat1添加上去，将tomcat2停掉
    echo "stop_apache-tomcat2"
    sed -i 's#server 127.0.0.1:8081 down;#server 127.0.0.1:8081;#' $nginx_conf
    sed -i 's#server 127.0.0.1:8082;#server 127.0.0.1:8082 down;#' $nginx_conf
    $nginx -s reload

    echo 'start deploy tomcat2 node '
    tomcat_deploy tomcat2

    #将tomcat2重新加入池子
    sed -i 's#server 127.0.0.1:8082 down;#server 127.0.0.1:8082;#' $nginx_conf
    $nginx -s reload
}


rollback(){
    tomcat_rollback tomcat1
    tomcat_rollback tomcat2
}



case "$1" in
'deploy')
   deploy
   echo "deploy success!!!"  
;;
'rollback')
   rollback
   echo "rollback success!!!"  
;;
*)
   echo "Usage: $0 {deploy | rollback}"  
   exit 1
esac