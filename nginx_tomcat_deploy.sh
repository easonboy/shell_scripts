#!/bin/bash
#定义nginx反向代理配置文件

nginx=/usr/local/nginx/sbin/nginx
nginx_conf=/usr/local/nginx/conf/extra/upstream.conf



function deploy()

{

#echo $1
/etc/init.d/$1 stop || ps -ef|grep $1|grep -v 'grep'|xargs kill -9

sleep 10

cd /usr/local/apache-$1/webapps/
mv ROOT.war ROOT.wa && rm -rf ROOT 

cp  /usr/local/src/ROOT-prd.war /usr/local/apache-$1/webapps/ROOT.war

/etc/init.d/$1 start 

sleep 15

}


#将tomcat1从池子中下掉

sed -i 's#server 127.0.0.1:8081;#server 127.0.0.1:8081 down;#' $nginx_conf && nginx -s reload

echo 'start deploy tomcat1 node'

deploy tomcat1


#将tomcat1重新加入池子，并将tomcat2下池子

sed -i 's#server 127.0.0.1:8081 down;#server 127.0.0.1:8081;#' $nginx_conf
sed -i 's#server 127.0.0.1:8082;#server 127.0.0.1:8082 down;#' $nginx_conf
$nginx -s reload

echo 'start deploy tomcat2 node '
deploy tomcat2 

#将tomcat2重新加入池子
sed -i 's#server 127.0.0.1:8082 down;#server 127.0.0.1:8082;#' $nginx_conf
$nginx -s reload
