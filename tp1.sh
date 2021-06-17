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
echo "=========START creation vpc=======" >> trace.log
AWSVPC=$($AWSBIN ec2 create-vpc --cidr-block "$VPCCIDRBLK" --instance-tenancy default --endpoint $ZONE)
echo $AWSVPC >> trace.log
IDVPC=$(echo -e "$AWSVPC" |  jq '.Vpc.VpcId' | tr -d '"')
echo $IDVPC >> trace.log
echo "=========END creation vpc=======" >> trace.log
echo "" >> trace.log

#public
echo "=========START creation subnet public=======" >> trace.log
AWSVPCSUB1=$($AWSBIN ec2 create-subnet --vpc-id $IDVPC --cidr-block "$PRIVSUBNET")
RETAWSVPCSUB1ID=$(echo -e "$AWSVPCSUB1" |  jq '.Subnet.SubnetId' | tr -d '"')
echo "=========END creation subnet public=======" >> trace.log
echo "" >> trace.log

#prive
echo "=========START creation subnet prive=======" >> trace.log
AWSVPCSUB2=$($AWSBIN ec2 create-subnet --vpc-id $IDVPC --cidr-block "$PUBSUBNET")
RETAWSVPCSUB2ID=$(echo -e "$AWSVPCSUB2" |  jq '.Subnet.SubnetId' | tr -d '"')
echo "=========END creation subnet prive=======" >> trace.log
echo "" >> trace.log

#creation de la GW internet
echo "=========START creation GW internet=======" >> trace.log
RETIGW=$($AWSBIN ec2 create-internet-gateway )
echo $RETIGW >> trace.log
RETIGWID=$(echo -e "$RETIGW" |  jq '.InternetGateway.InternetGatewayId' | tr -d '"')
echo $RETIGWID >> trace.log
echo "=========END creation GW internet=======" >> trace.log
echo "" >> trace.log

#attache GW to VPC
echo "=========START attache GW to VPC=======" >> trace.log
RETGWTOVPCLNK=$($AWSBIN ec2 attach-internet-gateway --internet-gateway-id "$RETIGWID" --vpc-id "$IDVPC")
echo "=========END attache GW to VPC=======" >> trace.log
echo "" >> trace.log


#Creation d'une table de route
echo "=========START Creation d'une table de route=======" >> trace.log
RETROUTETAB=$($AWSBIN ec2 create-route-table --vpc-id "$IDVPC")
echo $RETROUTETAB >> trace.log
RETROUTETABID=$(echo -e "$RETROUTETAB" |  jq '.RouteTable.RouteTableId' | tr -d '"')
echo $RETROUTETABID >> trace.log
echo "=========END Creation d'une table de route=======" >> trace.log
echo "" >> trace.log

#Creation d'une route vers la passerelle internet
echo "=========START Creation d'une route vers la passerelle internet=======" >> trace.log
RETROUTETOGWI=$($AWSBIN ec2 create-route --route-table-id "$RETROUTETABID" --destination-cidr-block "$CIDRBLOCK" --gateway-id "$RETIGWID")
echo $RETROUTETOGWI >> trace.log
echo "=========END d'une route vers la passerelle internet=======" >> trace.log
echo "" >> trace.log

#Association du sous-réseau public à la table de route
echo "=========START Association du sous-réseau public à la table de route=======" >> trace.log
RETSUBPUBTOROUTE=$($AWSBIN ec2 associate-route-table --subnet-id "$RETAWSVPCSUB1ID" --route-table-id "$RETROUTETABID")
echo $RETROUTETOGWI >> trace.log
echo "=========END  Association du sous-réseau public à la table de route=======" >> trace.log
echo "" >> trace.log

#enable public ip on subnet
echo "=========START enable public ip on subnet=======" >> trace.log
RETPUBIP=$($AWSBIN ec2 modify-subnet-attribute --subnet-id "$RETAWSVPCSUB1ID" --map-public-ip-on-launch)
echo $RETPUBIP >> trace.log
echo "=========END  enable public ip on subnet=======" >> trace.log
echo "" >> trace.log

#add DNS
#RETDNS=$(aw$AWSBINs ec2 modify-vpc-attribute --vpc-id "$IDVPC" --enable-dns-hostnames "{\"Value\":true}")


#creation paire cle SSH clé déjà créé réutilisation

#Droits clé SSH


#creation groupe de secu
echo "=========START creation groupe de secu=======" >> trace.log
AWSGRPSEC=$($AWSBIN ec2 create-security-group --group-name "$SECGRPNAME" --description "GB TP1 GRP SECU" --vpc-id "$echo $IDVPC")
echo $AWSGRPSEC >> trace.log
IDGRP=$(echo -e "$AWSGRPSEC" |  jq '.GroupId' | tr -d '"')
echo $IDGRP  >> trace.log
echo "=========END  creation groupe de secu=======" >> trace.log
echo "" >> trace.log

#activation port 22
echo "=========START activation port 22=======" >> trace.log
RETSSH=$($AWSBIN ec2 authorize-security-group-ingress --group-id "$IDGRP" --protocol tcp --port 22 --cidr "$CIDRBLOCK")
echo $RETSSH >> trace.log
echo "=========END  activation port 22=======" >> trace.log
echo "" >> trace.log

#activation port 80
echo "=========START activation port 80=======" >> trace.log
RETHTTP=$($AWSBIN ec2 authorize-security-group-ingress --group-id "$IDGRP" --protocol tcp --port 80 --cidr "$CIDRBLOCK")
echo $RETHTTP >> trace.log
echo "=========END  activation port 80=======" >> trace.log
echo "" >> trace.log

#creation NAT GW
#extraire info NAt GW avec le query
#aws ec2 describe-nat-gateways --query 'NatGateways[*].NatGatewayAddresses[*].PublicIp'

#creation de l'instance
echo "=========START creation de l'instance=======" >> trace.log
RETEC2CREATE=$($AWSBIN ec2 run-instances --image-id $IMGID --count 1 --instance-type $INSTANCETYP --key-name $SSHKEYUSED --security-group-ids $IDGRP --subnet-id $RETAWSVPCSUB1ID --user-data file://install.sh)
#RETEC2CREATE=$($AWSBIN ec2 run-instances --image-id ami-00c08ad1a6ca8ca7c --count 1 --instance-type $INSTANCETYP --key-name tp1GB --security-group-ids $IDGRP --subnet-id $RETAWSVPCSUB1ID)
echo $RETEC2CREATE >> trace.log
echo "=========END  creation de l'instance=======" >> trace.log
echo "" >> trace.log
