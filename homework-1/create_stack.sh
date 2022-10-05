#!/bin/sh

aws cloudformation create-stack --stack-name 'Stack1' --template-body file://infrastructure.json