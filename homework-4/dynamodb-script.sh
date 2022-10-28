#!/bin/sh

if [ -n "$1" ] ; then
    PROFILE="--profile $1"
else
    PROFILE=""
fi

if [ -z "$REGION" ] ; then
    REGION="us-west-2"
fi

aws $PROFILE dynamodb list-tables
aws $PROFILE dynamodb put-item --table-name Devices --item '{"Type":{"S":"Computer"}, "Place":{"S":"Living room"}, "OS": {"S":"Windows"}}'
aws $PROFILE dynamodb get-item --table-name Devices --key '{"Type":{"S":"Computer"}}'

