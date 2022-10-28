#!/bin/sh

if [ -n "$1" ] ; then
    PROFILE="--profile $1"
else
    PROFILE=""
fi

if [ -z "$REGION" ] ; then
    REGION="us-west-2"
fi


BUCKET="gene-homework-4.dekis.org"
URL=`aws $PROFILE s3api create-bucket --region $REGION --bucket $BUCKET --create-bucket-configuration LocationConstraint=$REGION --output text`
if [ $? -ne 0 ] ; then
    exit
fi

RDS_SCRIPT=rds-script.sql
aws $PROFILE s3api put-object --bucket $BUCKET --key $RDS_SCRIPT  --content-type 'application/sql' --body $RDS_SCRIPT --output text
if [ $? -ne 0 ] ; then
    exit
fi

DYNAMO_SCRIPT=dynamodb-script.sh
aws $PROFILE s3api put-object --bucket $BUCKET --key $DYNAMO_SCRIPT  --content-type 'application/x-sh' --body $DYNAMO_SCRIPT --output text
if [ $? -ne 0 ] ; then
    exit
fi

echo $URL
