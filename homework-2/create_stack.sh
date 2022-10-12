#!/bin/sh
# Preconditions:
# no key-pair 'lab-key'
# no stack 'Stack1'

if [ -n "$1" ] ; then
    PROFILE="--profile $1"
else
    PROFILE=""
fi
aws $PROFILE ec2 create-key-pair --key-name lab-key --key-type rsa --query "KeyMaterial" --output text > lab-key.pem
aws $PROFILE cloudformation create-stack --stack-name 'Stack1' --template-body file://infrastructure.json
