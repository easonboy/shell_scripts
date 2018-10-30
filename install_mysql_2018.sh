#!/bin/bash
mysql_menu() {
cat <<EOF
Please select mysql verson
----------------------------------
   1.[mysql_5.5.60]

   2.[mysql_5.6.40]
   
   3.[exit]
-----------------------------------
EOF
}


get_repo() {
  ls /etc/yum.repos.d/epel.repo &>/dev/null
  if [ $? -ne  0 ];then
  s=`rpm -qa wget`
  [ -z "$s" ] && yum install -y wget &>/dev/null
  v=`uname -r|sed -r 's#(.*.el)([0-9])(\..*)#\2#g'`
  wget -q -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-"$v".repo &>/dev/null
fi
}


check_user() {
  grep -qw "$1" /etc/passwd
  if [ $? -ne 0 ];then
     useradd $1  -M -s /sbin/nologin
  fi 
}


check_url() {
   cd /usr/local/src
   name=`basename $1`
   ls $name &>/dev/null
   RETVEL=$?
   dname=`echo $name|awk -F '-' '{print $1}'`
   echo -e  "\033[32mStart install $dname  Please wait\033[0m"
   sleep 2
   if [ $RETVEL -ne 0 ];then
     wget  -t 3 -T 30  $1
     [ $? -ne 0 ] && echo -e "\033[31m$dname  not download,Pls check url\033[0m" && exit 2
  fi
}




#定义变量
define_var() {
  cd /usr/local/src
  version=`uname -i`
  basedir='/usr/local/mysql'
  datadir='/data/mysql'
  [ ! -d $basedir ] && mkdir -p $datadir
  check_user mysql
  chown -R mysql:mysql /data/mysql
}

mysql_depend() {
array=(numactl)
for package in ${array[@]}
do
   s=`rpm -qa $package`
   [ -z "$s" ]&& yum install -y $package
done
}



#输入对应id,下载对应mysql版本
select_id() {
  read -p 'Pls select Id:' id
  if [ "$id" = "1" ];then
    url=http://mirrors.sohu.com/mysql/MySQL-5.5/mysql-5.5.60-linux-glibc2.12-"$version".tar.gz
  elif [ "$id" = "2" ];then
    url=http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.40-linux-glibc2.12-"$version".tar.gz
  elif [ "$id" = "3" ];then
       echo 'bye'
       exit 1
  else 
    echo 'Input error'
    exit 1
fi 
}



#多个版本公用模版
mysql_public() {
  mysql_menu
  select_id
  mysql_depend
  check_url $url
  tar -zxf  $name
  sleep 3
  name=`echo $name|sed 's#.tar.gz##g'`
  echo $name|awk -F '-' '{print "mv",$0,"/usr/local/"$1 }' |bash
  cd $basedir
  echo -e "\033[33mMysql start initialization.........\033[0m"
  sleep 2
  ./scripts/mysql_install_db --user=mysql --datadir=$datadir
  if  [ $? -eq 0 ];then
    /bin/cp support-files/my-medium.cnf  /etc/my.cnf &>/dev/null || /bin/cp support-files/my-default.cnf /etc/my.cnf
    /bin/cp support-files/mysql.server /etc/init.d/mysqld
    sed  -i "s#^basedir=#basedir=$basedir#g" /etc/init.d/mysqld
    sed  -i "s#^datadir=#datadir=$datadir#g" /etc/init.d/mysqld
    chmod 755 /etc/init.d/mysqld
    chkconfig --add mysqld
    chkconfig mysqld on
    /etc/init.d/mysqld start
    [ $? -eq  0 ]&&echo -e "\033[32mMysql Install Scuessfule\033[0m"||echo -e "\033[32mMysql Install Failure!\033[0m"
  else
    echo  -e "\033[31mMysql initialization Failure!\033[0m"
     exit 1
  fi
}






install_mysql() {
  define_var
  ls $basedir &>/dev/null
  if [ $? -ne 0 ];then
     mysql_public
  else
     echo  -e "\033[31mMysqld Already install\033[0m"
    exit 1
 fi 
}


install_mysql
