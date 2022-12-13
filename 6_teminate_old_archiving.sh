#!/bin/bash

old_archiving_asg_name="Archiving-DEVL-staging-Simplified-$(cat ./old_color  | awk '{print tolower($0)}')"

. ./0_aws_creds.sh

aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$old_archiving_asg_name" --min-size 0 --max-size 0 --desired-capacity 0
echo "Updated $old_archiving_asg_name to set all sizes to 0."