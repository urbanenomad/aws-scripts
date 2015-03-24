#!/bin/bash

NAME=$1
PROFILE=$2
TAGKEY=$3
TAGVALUE=$4

REGION=us-west-2

aws --profile $PROFILE --region $REGION ec2 describe-instances \
--query "Reservations[].Instances[].InstanceId" \
--filters "Name=tag-key,Values=$TAGKEY,Name=tag-value,Values=$TAGVALUE" \
| while read x;
do 
	if [ $x != "]" ] && [ $x != "[" ]; then
		INST_ID="${x//,}";
		echo $INST_ID
		aws --profile $PROFILE  \
		--region $REGION \
		cloudwatch put-metric-alarm \
		--alarm-name $NAME \
		--alarm-description "Stop the instance when it is idle for a day" \
		--namespace "AWS/EC2" \
		--dimensions Name=InstanceId,Value=$INST_ID \
		--statistic Average \
		--metric-name CPUUtilization \
		--comparison-operator LessThanThreshold \
		--threshold 10 \
		--period 86400 \
		--evaluation-periods 1 \
		--alarm-actions arn:aws:automate:$REGION:ec2:stop
	fi
done


