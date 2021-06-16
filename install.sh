#!/bin/bash

yum install httpd openssl php-common php-curl php-json php-mbstring php-mysql php-xml php-zip
yum install mysql-server
service mysqld start
mysqladmin -u root create blog
(echo
echo Y
echo password
echo Y
echo Y
echo Y
echo Y
)| mysql_secure_installation

cd /var/www/html
wget http://wordpress.org/latest.tar.gz
tar -xzvf latest-fr_FR.tar.gz .