#!/bin/sh
aws s3 cp s3://lohika-homework-u5saog/calc-2021-0.0.1-SNAPSHOT.jar ~ec2-user/
sudo amazon-linux-extras enable corretto8
sudo yum -y install java-1.8.0-amazon-corretto.x86_64
sudo java -jar ./calc-2021-0.0.1-SNAPSHOT.jar
