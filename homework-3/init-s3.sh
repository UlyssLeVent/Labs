#!/bin/sh

tmpfile=motd.txt

clear ()
{
    rm $tmpfile
}

if [ -n "$1" ] ; then
    PROFILE="--profile $1"
else
    PROFILE=""
fi

if [ -z "$REGION" ] ; then
    REGION="us-west-2"
fi

trap clear 2 3 15

cat > motd.txt <<EOF
Set your course by the stars, not by the lights of every passing ship.
-- Omar N. Bradley
EOF

BUCKET=`mktemp -u gene-homework-3-XXXXXX | tr -s ABCDEFGHIJKLMNOPQARTUVWXYZ abcdefghijklmnopqrstuvwxyz`
URL=`aws $PROFILE s3api create-bucket --region $REGION --bucket $BUCKET --create-bucket-configuration LocationConstraint=$REGION --output text`
if [ $? -ne 0 ] ; then
    clear
    exit
fi

aws $PROFILE s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration  '{"MFADelete":"Disabled","Status":"Enabled"}'
if [ $? -ne 0 ] ; then
    clear
    exit
fi

aws $PROFILE s3api put-object --bucket $BUCKET --key $tmpfile --content-type 'text/plain' --body $tmpfile --output text
if [ $? -ne 0 ] ; then
    clear
    exit
fi

echo "bucket = $BUCKET" > terraform.tfvars
echo "motd   = $tmpfile" >> terraform.tfvars

cat > setup.sh <<EOF
#!/bin/sh
aws s3 cp s3://$BUCKET/$tmpfile ./
EOF

clear
