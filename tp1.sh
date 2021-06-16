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
ZONE="https://ec2.eu-west-3.amazonaws.com"
SECGRPNAME="gbtp1SecurityGroup"

#creation vpc
AWSVPC=$($AWSBIN ec2 create-vpc --cidr-block "$VPCCIDRBLK" --instance-tenancy default --endpoint $ZONE)
echo $AWSVPC >> trace.log
IDVPC=$(echo -e "$AWSVPC" |  jq '.Vpc.VpcId' | tr -d '"')
echo $IDVPC >> trace.log

#public
AWSVPCSUB1=$($AWSBIN ec2 create-subnet --vpc-id $IDVPC --cidr-block 10.77.87.0/24)
RETAWSVPCSUB1=$(echo -e "$AWSVPCSUB1" |  jq '.Subnet.SubnetId' | tr -d '"')
#prive
AWSVPCSUB2=$($AWSBIN ec2 create-subnet --vpc-id $IDVPC --cidr-block 10.77.187.0/24)
RETAWSVPCSUB2=$(echo -e "$AWSVPCSUB2" |  jq '.Subnet.SubnetId' | tr -d '"')

#enable public ip on subnet
RETPUBIP=$($AWSBIN ec2 modify-subnet-attribute --subnet-id "$RETAWSVPCSUB1" --map-public-ip-on-launch)
echo $RETPUBIP >> trace.log

#add DNS
#RETDNS=$(aw$AWSBINs ec2 modify-vpc-attribute --vpc-id "$IDVPC" --enable-dns-hostnames "{\"Value\":true}")

#creation groupe de secu
AWSGRPSEC=$($AWSBIN ec2 create-security-group --group-name "$SECGRPNAME" --description "GB TP1 GRP SECU" --vpc-id "$echo $IDVPC")
echo $AWSGRPSEC >> trace.log
IDGRP=$(echo -e "$AWSGRPSEC" |  jq '.GroupId' | tr -d '"')
echo $IDGRP  >> trace.log

#activation port 22
RETSSH=$($AWSBIN ec2 authorize-security-group-ingress --group-id "$IDGRP" --protocol tcp --port 22 --cidr "0.0.0.0/0")
echo $RETSSH >> trace.log

#activation port 80
RETHTTP=$($AWSBIN ec2 authorize-security-group-ingress --group-id "$IDGRP" --protocol tcp --port 80 --cidr "0.0.0.0/0")
echo $RETHTTP >> trace.log

#creation de la GW internet
RETIGW=$($AWSBIN ec2 create-internet-gateway )
echo $RETIGW >> trace.log
RETIGWID=$(echo -e "$RETIGW" |  jq '.InternetGateway.InternetGatewayId' | tr -d '"')
echo $RETIGWID >> trace.log

#attache GW to VPC
RETGWTOVPCLNK=$($AWSBIN ec2 attach-internet-gateway --internet-gateway-id "$RETIGWID" --vpc-id "$IDVPC")

#creation NAT GW
#extraire info NAt GW avec le query
#aws ec2 describe-nat-gateways --query 'NatGateways[*].NatGatewayAddresses[*].PublicIp'

#creation de l'instance
RETEC2CREATE=$($AWSBIN ec2 run-instances --image-id ami-00c08ad1a6ca8ca7c --count 1 --instance-type t2.micro --key-name tp1GB --security-group-ids $IDGRP --subnet-id $RETAWSVPCSUB1 --user-data file://install.sh)
#RETEC2CREATE=$($AWSBIN ec2 run-instances --image-id ami-00c08ad1a6ca8ca7c --count 1 --instance-type t2.micro --key-name tp1GB --security-group-ids $IDGRP --subnet-id $RETAWSVPCSUB1)
echo $RETEC2CREATE >> trace.log

