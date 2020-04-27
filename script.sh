#!/bin/bash
##  Purpose: In AWS Deregister OLD AMIs and their Snapshots
##  Usage: sh deregisterOldAMIandSnapshots.sh <<date in YYYY-MM-DD>> owner
##          date : AMI before this date will be deleted
##          owner : Owner of the account
##          Deregister AMI and its snapshot as per date configured in scripts.

## Variable declarations
v_owner=$2
v_region=us-east-1
v_ami_name=(team1 team2 team3)

input=`echo $1 | awk '{print tolower($0)}'`
if [ "$input" == "help" ] || [ $# -eq 0 ]; then
  echo "Usage:: sh deregisterOldAMIandSnapshots.sh <<date in YYYY-MM-DD>> owner"
  echo "           date : AMI before this date will be deleted"
  echo "           owner : Owner of the account"
  echo "           Deregister AMI and its snapshot as per date configured in scripts."
  exit 0
fi

#if date -v-30d > /dev/null 2>&1; then
    # BSD systems (Mac OS X)
#    DATE=date -v-30d +%Y-%m-%d
#else
    # GNU systems (Linux)
#    DATE=date --date="-30 days" +%Y-%m-%d
#fi

v_ami_name_lenght=${#v_ami_name[@]}
for (( i=0; i<v_ami_name_lenght; i++ ))
do
  v_array_ami=( $(aws ec2 describe-images --owner $v_owner --region $v_region \
   --query "Images[?CreationDate<='$input'].ImageId" \
   --filters "Name=name,Values=${v_ami_name[$i]}*"  \
   --output text))

  v_array_ami_lenght=${#v_array_ami[@]}

  if (( $v_array_ami_lenght == 0 )); then
    echo "No AMI to degister for AMI name starting with ${v_ami_name[$i]}.. Done nothing.."
  fi

  for (( j=0; j<v_array_ami_lenght; j++ ))
  do
    temp_ami_id=${v_array_ami[$j]}
    v_array_snapshot=( $(aws ec2 describe-images --owner $v_owner --region $v_region \
     --image-ids $temp_ami_id \
     --output text \
     --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId'))

    v_array_snapshot_lenght=${#v_array_snapshot[@]}

   v_creationdate=( $(aws ec2 describe-images --owner $v_owner --region $v_region \
     --image-ids $temp_ami_id \
     --output text \
     --query 'Images[*].CreationDate'))

    echo "Deregistering AMI: $temp_ami_id, created on $v_creationdate"
    aws ec2 deregister-image --image-id $temp_ami_id --region $v_region

    echo "  Removing Snapshots.."

    for (( k=0; k<$v_array_snapshot_lenght; k++ ))
    do
      temp_snapshot_id=${v_array_snapshot[$k]}
      echo "  Deleting Snapshot: $temp_snapshot_id"
      aws ec2 delete-snapshot --snapshot-id $temp_snapshot_id --region $v_region
    done
  done
done
exit 0
