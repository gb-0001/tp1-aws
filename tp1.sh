#!/bin/bash

#Installation des packages
install_package() {
    PACKAGE="$1"
    if ! dpkg -l |grep --quiet "^ii.*$PACKAGE "; then
        sudo apt install -y "$PACKAGE"
    fi
}

#parser json
install_package "jq"

#RAZ trace.log
echo "" > trace.log

#PATH AWSBIN
AWSBIN=/usr/local/bin/aws
VPCCIDRBLK="10.77.0.0/16"
PRIVSUBNET="10.77.87.0/24"
PUBSUBNET="10.77.187.0/24"
CIDRBLOCK="0.0.0.0/0"
ZONE="https://ec2.eu-west-3.amazonaws.com"
SECGRPNAME="gbtp1SecurityGroup"
SSHKEYUSED="tp1GB"
INSTANCETYP="t2.micro"
#LINUX AMZ
IMGID="ami-00c08ad1a6ca8ca7c"

#creation vpc
echo "=========START creation vpc=======" 1>>trace.log 2>&1
AWSVPC=$($AWSBIN ec2 create-vpc --cidr-block "$VPCCIDRBLK" --instance-tenancy default --endpoint $ZONE)
echo $AWSVPC 1>>trace.log 2>&1
IDVPC=$(echo -e "$AWSVPC" |  jq '.Vpc.VpcId' | tr -d '"')
echo $IDVPC 1>>trace.log 2>&1
echo "=========END creation vpc=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#public
echo "=========START creation subnet public=======" 1>>trace.log 2>&1
AWSVPCSUB1=$($AWSBIN ec2 create-subnet --vpc-id $IDVPC --cidr-block "$PRIVSUBNET")
RETAWSVPCSUB1ID=$(echo -e "$AWSVPCSUB1" |  jq '.Subnet.SubnetId' | tr -d '"')
echo "=========END creation subnet public=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#prive
echo "=========START creation subnet prive=======" 1>>trace.log 2>&1
AWSVPCSUB2=$($AWSBIN ec2 create-subnet --vpc-id $IDVPC --cidr-block "$PUBSUBNET")
RETAWSVPCSUB2ID=$(echo -e "$AWSVPCSUB2" |  jq '.Subnet.SubnetId' | tr -d '"')
echo "=========END creation subnet prive=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#creation de la GW internet
echo "=========START creation GW internet=======" 1>>trace.log 2>&1
RETIGW=$($AWSBIN ec2 create-internet-gateway )
echo $RETIGW 1>>trace.log 2>&1
RETIGWID=$(echo -e "$RETIGW" |  jq '.InternetGateway.InternetGatewayId' | tr -d '"')
echo $RETIGWID 1>>trace.log 2>&1
echo "=========END creation GW internet=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#attache GW to VPC
echo "=========START attache GW to VPC=======" 1>>trace.log 2>&1
RETGWTOVPCLNK=$($AWSBIN ec2 attach-internet-gateway --internet-gateway-id "$RETIGWID" --vpc-id "$IDVPC")
echo "=========END attache GW to VPC=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1


#Creation d'une table de route
echo "=========START Creation d'une table de route=======" 1>>trace.log 2>&1
RETROUTETAB=$($AWSBIN ec2 create-route-table --vpc-id "$IDVPC")
echo $RETROUTETAB 1>>trace.log 2>&1
RETROUTETABID=$(echo -e "$RETROUTETAB" |  jq '.RouteTable.RouteTableId' | tr -d '"')
echo $RETROUTETABID 1>>trace.log 2>&1
echo "=========END Creation d'une table de route=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#Creation d'une route vers la passerelle internet
echo "=========START Creation d'une route vers la passerelle internet=======" 1>>trace.log 2>&1
RETROUTETOGWI=$($AWSBIN ec2 create-route --route-table-id "$RETROUTETABID" --destination-cidr-block "$CIDRBLOCK" --gateway-id "$RETIGWID")
echo $RETROUTETOGWI 1>>trace.log 2>&1
echo "=========END d'une route vers la passerelle internet=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#Association du sous-réseau public à la table de route
echo "=========START Association du sous-réseau public à la table de route=======" 1>>trace.log 2>&1
RETSUBPUBTOROUTE=$($AWSBIN ec2 associate-route-table --subnet-id "$RETAWSVPCSUB1ID" --route-table-id "$RETROUTETABID")
echo $RETROUTETOGWI 1>>trace.log 2>&1
echo "=========END  Association du sous-réseau public à la table de route=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#enable public ip on subnet
echo "=========START enable public ip on subnet=======" 1>>trace.log 2>&1
RETPUBIP=$($AWSBIN ec2 modify-subnet-attribute --subnet-id "$RETAWSVPCSUB1ID" --map-public-ip-on-launch)
echo $RETPUBIP 1>>trace.log 2>&1
echo "=========END  enable public ip on subnet=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#add DNS
#RETDNS=$(aw$AWSBINs ec2 modify-vpc-attribute --vpc-id "$IDVPC" --enable-dns-hostnames "{\"Value\":true}")


#creation paire cle SSH clé déjà créé réutilisation

#Droits clé SSH


#creation groupe de secu
echo "=========START creation groupe de secu=======" 1>>trace.log 2>&1
AWSGRPSEC=$($AWSBIN ec2 create-security-group --group-name "$SECGRPNAME" --description "GB TP1 GRP SECU" --vpc-id "$echo $IDVPC")
echo $AWSGRPSEC 1>>trace.log 2>&1
IDGRP=$(echo -e "$AWSGRPSEC" |  jq '.GroupId' | tr -d '"')
echo $IDGRP  1>>trace.log 2>&1
echo "=========END  creation groupe de secu=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#activation port 22
echo "=========START activation port 22=======" 1>>trace.log 2>&1
RETSSH=$($AWSBIN ec2 authorize-security-group-ingress --group-id "$IDGRP" --protocol tcp --port 22 --cidr "$CIDRBLOCK")
echo $RETSSH 1>>trace.log 2>&1
echo "=========END  activation port 22=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#activation port 80
echo "=========START activation port 80=======" 1>>trace.log 2>&1
RETHTTP=$($AWSBIN ec2 authorize-security-group-ingress --group-id "$IDGRP" --protocol tcp --port 80 --cidr "$CIDRBLOCK")
echo $RETHTTP 1>>trace.log 2>&1
echo "=========END  activation port 80=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

#creation NAT GW
#extraire info NAt GW avec le query
#aws ec2 describe-nat-gateways --query 'NatGateways[*].NatGatewayAddresses[*].PublicIp'

#creation de l'instance
echo "=========START creation de l'instance=======" 1>>trace.log 2>&1
RETEC2CREATE=$($AWSBIN ec2 run-instances --image-id $IMGID --count 1 --instance-type $INSTANCETYP --key-name $SSHKEYUSED --security-group-ids $IDGRP --subnet-id $RETAWSVPCSUB1ID --user-data file://install.sh)
#RETEC2CREATE=$($AWSBIN ec2 run-instances --image-id ami-00c08ad1a6ca8ca7c --count 1 --instance-type $INSTANCETYP --key-name tp1GB --security-group-ids $IDGRP --subnet-id $RETAWSVPCSUB1ID)
echo $RETEC2CREATE 1>>trace.log 2>&1
echo "=========END  creation de l'instance=======" 1>>trace.log 2>&1
echo "" 1>>trace.log 2>&1

cat trace.log