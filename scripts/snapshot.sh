#!/bin/bash
IMAGES="$1"

CTR_CMD="apiclient exec admin sheltie ctr -a /run/containerd/containerd.sock -n k8s.io"

if [ -z "${INSTANCE_ID}" ]; then
    echo "Please set Instance ID"
    exit 1
fi

if [ -z "${AWS_REGION}" ]; then
    echo "Please set AWS region"
    exit 1
fi

if [ -z "${IMAGES}" ]; then
    echo "Please set images list"
    exit 1
fi

IMAGES_LIST=(`echo $IMAGES | sed 's/,/\n/g'`)
export AWS_PAGER=""
AWS_DEFAULT_REGION=$AWS_REGION

echo -n "Waiting for the instance .."
while [[ $(aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$INSTANCE_ID" --query "InstanceInformationList[0].PingStatus" --output text) != "Online" ]]
do
   echo -n "."
   sleep 5
done
echo " done!"

echo -n "Stopping kubelet.service .."
CMDID=$(aws ssm send-command --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" --comment "Stop kubelet" \
    --parameters commands="apiclient exec admin sheltie systemctl stop kubelet" \
    --query "Command.CommandId" --output text)
aws ssm wait command-executed --command-id "$CMDID" --instance-id $INSTANCE_ID > /dev/null
echo " done!"

echo -n "Cleanup existing images .."
CMDID=$(aws ssm send-command --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" --comment "Cleanup existing images" \
    --parameters commands="$CTR_CMD images rm \$($CTR_CMD images ls -q)" \
    --query "Command.CommandId" --output text)
aws ssm wait command-executed --command-id "$CMDID" --instance-id $INSTANCE_ID > /dev/null
echo " done!"

echo -n "Pulling $IMAGES_LIST .."
for IMG in "${IMAGES_LIST[@]}"
do
  CMDID=$(aws ssm send-command --instance-ids $INSTANCE_ID \
      --document-name "AWS-RunShellScript" --comment "Pull Images" \
      --parameters commands="$CTR_CMD images pull --platform amd64 $IMG" \
      --query "Command.CommandId" --output text)
  while [[ $(aws ssm list-commands --command-id "$CMDID" --query "Commands[0].Status" --output text) != "Success" ]]
  do
    echo -n "."
    sleep 30
  done
done
echo " done!"

echo -n "Creating snapshot .."
DATA_VOLUME_ID=$(aws ec2 describe-instances  --instance-id $INSTANCE_ID --query "Reservations[0].Instances[0].BlockDeviceMappings[?DeviceName=='/dev/xvdb'].Ebs.VolumeId" --output text)
SNAPSHOT_ID=$(aws ec2 create-snapshot --volume-id $DATA_VOLUME_ID --description "Bottlerocket Data Volume snapshot" --query "SnapshotId" --output text)
until aws ec2 wait snapshot-completed --snapshot-ids "$SNAPSHOT_ID" 2>/dev/null
do
  echo -n "."
  sleep 30
done
echo " done!"
echo "--------------------------------------------------"
echo "Created snapshot in $AWS_REGION: $SNAPSHOT_ID"
echo "Create env with the command: export SNAPSHOT_ID=$SNAPSHOT_ID"
