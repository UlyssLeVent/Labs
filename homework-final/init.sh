#!/bin/sh

TFVARS=terraform.tfvars
if [ -n "$1" ] ; then
    PROFILE="--profile $1"
else
    PROFILE=""
fi

if [ -z "$REGION" ] ; then
    REGION="us-west-2"
fi


if [ -s $TFVARS ] ; then
    OLD_IFS=$IFS
    IFS=${IFS}=
    while read name value; do
        IFS=$OLD_IFS
        eval ${name}=${value}
        IFS=${IFS}=
    done < $TFVARS
fi
IFS=$OLD_IFS


if [ "X$bucket" = "X" ] ; then
    bucket=`mktemp -u lohika-homework-XXXXXX | tr -s ABCDEFGHIJKLMNOPQARTUVWXYZ abcdefghijklmnopqrstuvwxyz`
    echo "bucket = \"$bucket\"" >> $TFVARS
fi

aws $PROFILE s3 ls s3://$bucket > /dev/null 2>/dev/null
if [ $? -ne 0 ] ; then
    echo "Creating new bucket $bucket"

    URL=`aws $PROFILE s3api create-bucket --region $REGION --bucket $BUCKET --create-bucket-configuration LocationConstraint=$REGION --output text`
    if [ $? -ne 0 ] ; then
        exit
    fi
    #aws $PROFILE s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration  '{"MFADelete":"Disabled","Status":"Enabled"}'
    #if [ $? -ne 0 ] ; then
    #    clear
    #    exit
    #fi

else
    echo "Using configured bucket $bucket"
fi

echo Upload *.jar files

for jar in *.jar; do
    aws $PROFILE s3api put-object --bucket $bucket --key $jar --content-type 'applicationn/java' --body $jar --output text
    if [ $? -ne 0 ] ; then
        clear
        exit
    fi
done

aws $PROFILE s3 ls s3://$bucket/

cat > setup-web.sh <<EOF
#!/bin/sh
aws s3 cp s3://$bucket/calc-2021-0.0.1-SNAPSHOT.jar ~ec2-user/
sudo amazon-linux-extras enable corretto8
sudo yum -y install java-1.8.0-amazon-corretto.x86_64
sudo java -jar ./calc-2021-0.0.1-SNAPSHOT.jar
EOF
