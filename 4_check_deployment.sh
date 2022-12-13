#!/bin/bash

check_pipeline_states () {
    local status=$(aws codepipeline get-pipeline-state --name staging-dev-application --query 'stageStates[*].[stageName,latestExecution.status]')
    # local status=$(cat wait.sh)
    local stages_cnt=$(echo $status | jq -r '. | length')
    local stages_success_cnt=$(echo $status | jq -r '.[][1]' | grep -i "^Succeeded$" | wc -l)
    echo $status

    if [[ $stages_cnt -eq $stages_success_cnt ]]; then
        return 0
    else
        return 1
    fi
}

while sleep 1; do 
    echo "Checking code pipeline status... $(date)"
   if check_pipeline_states ; then
        echo "Pipeline Ok!"
        break
    fi
    printf "\033[2A"
done


check_target_states () {
    tg_all=0
    tg_ok=0
    while read arn 
    do
        if [ -z "${arn}" ]; then
            break
        fi
        tg_all=$((tg_all+1))

        echo $arn | sed "s/arn:aws:elasticloadbalancing:${AWS_DEFAULT_REGION}:${aws_account_id}:targetgroup\///"
        local status=$(aws elbv2 describe-target-health --target-group-arn $arn --query 'TargetHealthDescriptions[*].TargetHealth.State')
        echo $status
        local tg_cnt=$(echo $status | jq -r '. | length')
        local tg_success_cnt=$(echo $status | jq -r '.[]' | grep -i "^healthy$" | wc -l)
        if [[ $tg_cnt -gt "0" && $tg_cnt -eq $tg_success_cnt ]]; then
            tg_ok=$((tg_ok+1))
        fi
    done <<< "$(aws elbv2 describe-target-groups --names stagi-BlueT-1D6QFWTF27ZE2 stagi-BlueW-1AHDX2R97BL7J stagi-Green-1XC8N4YS3JGO7 stagi-Green-LRK8AWXMF0IC --query 'TargetGroups[*].TargetGroupArn' | jq -r '.[]')"

    if [[ $tg_ok -eq $tg_all ]]; then
        return 0
    else
        return $tg_all
    fi
}

while sleep 1; do 
    echo "Checking target group status... $(date)"
    check_target_states
    check_target_states_res=$?
    if [[ $check_target_states_res -eq "0" ]]; then
        echo "Target groups are Healthy!"
        break
    fi
    printf "\033[$((check_target_states_res * 2 + 1))A"
done


asg_color_total () {
    # local archiving_asg_tot=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "Archiving-DEVL-staging-Simplified-$1" --query 'AutoScalingGroups[*].[MinSize,MaxSize,DesiredCapacity]' | jq 'flatten | add')
    # local tracking_asg_tot=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "Tracking-DEVL-staging-Simplified-$1" --query 'AutoScalingGroups[*].[MinSize,MaxSize,DesiredCapacity]' | jq 'flatten | add')
    # local web_asg_tot=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "Web-DEVL-staging-Simplified-$1"  --query 'AutoScalingGroups[*].[MinSize,MaxSize,DesiredCapacity]' | jq 'flatten | add')
    # color_total=$((archiving_asg_tot + tracking_asg_tot + web_asg_tot))
    # echo $color_total

    aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "Archiving-DEVL-staging-Simplified-$1" "Tracking-DEVL-staging-Simplified-$1" "Web-DEVL-staging-Simplified-$1"  --query 'AutoScalingGroups[*].[MinSize,MaxSize,DesiredCapacity]' | jq 'flatten | add'

}

check_asg_sizes () {
    local blue_total=$(asg_color_total blue)
    local green_total=$(asg_color_total green)
    echo "Green=$green_total, Blue=$blue_total"
    if [[ $blue_total -eq $green_total ]]; then
        return 0
    else
        return 1
    fi
}

while sleep 1; do 
    echo "Checking ASG sizes for each color... $(date)"
   if check_asg_sizes ; then
        echo "Nice!, ASG sizes are also same."
        break
    fi
    printf "\033[2A"
done