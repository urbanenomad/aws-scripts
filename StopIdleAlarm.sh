#!/bin/bash

TAGKEY="AutoStop"
TAGVALUE="TRUE"
REGION=$1
PROF=$2



if [ ! -z $PROF ]; then
	PROFILE="--profile $PROF"	
else
	#if profile is not provided then you should fill in the ACCESS Key and Secret Key as ENV vars.
	export AWS_ACCESS_KEY_ID= #<<Add your access key>> 
	export AWS_SECRET_ACCESS_KEY= #<<Add your secret key>>
fi

if [ -z $REGION ]; then
	REGION=us-east-1
fi
if [ -z $ALARM_THRESHOLD ]; then
	ALARM_THRESHOLD=10 #10% utilization
fi
if [ -z $ALARM_PERIOD ]; then
	ALARM_PERIOD=86400 #60*60*24 minimum is 1 minute
fi

echo $PROFILE

aws $PROFILE --region $REGION ec2 describe-instances \
--query "Reservations[].Instances[].InstanceId" \
--filters "Name=tag-key,Values=$TAGKEY,Name=tag-value,Values=$TAGVALUE" \
| while read x;
do 
	if [ $x != "]" ] && [ $x != "[" ]; then
		INST_ID="${x//,}";
		TEMP=
		NAME="AUTOSTOP-$(echo $INST_ID | sed 's/"//g' )"
		echo $NAME

		aws $PROFILE  \
		--region $REGION \
		cloudwatch put-metric-alarm \
		--alarm-name $NAME  \
		--alarm-description "Stop the instance when it is idle for a day" \
		--namespace "AWS/EC2" \
		--dimensions Name=InstanceId,Value=$INST_ID \
		--statistic Average \
		--metric-name CPUUtilization \
		--comparison-operator LessThanThreshold \
		--threshold $ALARM_THRESHOLD \
		--period $ALARM_PERIOD \
		--evaluation-periods 1 \
		--alarm-actions arn:aws:automate:$REGION:ec2:stop
	fi
done
