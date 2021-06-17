#!/bin/bash

amazon-linux-extras install epel -y 1>>/tmp/trace.log 2>&1
yum install httpd openssl php-common php-curl php-json php-mbstring php-mysql php-xml php-zip -y 1>>/tmp/trace.log 2>&1
yum install mariadb-server -y 1>>/tmp/trace.log 2>&1
#yum install mysql-community-server -y 1>>/tmp/trace.log 2>&1
service mariadb start 1>>/tmp/trace.log 2>&1
service httpd start 1>>/tmp/trace.log 2>&1
#MYSQLPWD=$(grep 'temporary password' /var/log/mysqld.log | awk -F"root@localhost: " '{print $2}' | awk 1 ORS='' 1>>/tmp/trace.log 2>&1)
#echo $MYSQLPWD
mysqladmin -u root create blog 1>>/tmp/trace.log 2>&1
#(echo
#echo Y
#echo password
#echo Y
#echo Y
#echo Y
#echo Y
#)| mysql_secure_installation 1>>/tmp/trace.log 2>&1
mysql_secure_installation 1>>/tmp/trace.log 2>&1
cd /var/www/html 1>>/tmp/trace.log 2>&1
wget http://wordpress.org/latest.tar.gz 1>>/tmp/trace.log 2>&1
tar -xzvf latest.tar.gz 1>>/tmp/trace.log 2>&1
mv wordpress/* /var/www/html 1>>/tmp/trace.log 2>&1