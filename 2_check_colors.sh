#!/bin/bash
. ./0_aws_creds.sh

asg_color_total () {
    # local archiving_asg_tot=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "Archiving-DEVL-staging-Simplified-$1" --query 'AutoScalingGroups[*].[MinSize,MaxSize,DesiredCapacity]' | jq 'flatten | add')
    # local tracking_asg_tot=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "Tracking-DEVL-staging-Simplified-$1" --query 'AutoScalingGroups[*].[MinSize,MaxSize,DesiredCapacity]' | jq 'flatten | add')
    # local web_asg_tot=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "Web-DEVL-staging-Simplified-$1"  --query 'AutoScalingGroups[*].[MinSize,MaxSize,DesiredCapacity]' | jq 'flatten | add')
    # color_total=$((archiving_asg_tot + tracking_asg_tot + web_asg_tot))
    # echo $color_total

    aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "Archiving-DEVL-staging-Simplified-$1" "Tracking-DEVL-staging-Simplified-$1" "Web-DEVL-staging-Simplified-$1"  --query 'AutoScalingGroups[*].[MinSize,MaxSize,DesiredCapacity]' | jq 'flatten | add'

}

blue_total=$(asg_color_total blue)
green_total=$(asg_color_total green)

echo "ASG totals Green=$green_total, Blue=$blue_total"

if [[ $blue_total -eq 0 && $green_total -gt 0 ]]; then
    old_color='Green'
    new_color='Blue'
elif [[ $green_total -eq 0 && $blue_total -gt 0 ]]; then
    old_color='Blue'
    new_color='Green'
else
    echo "Unexpected results. ASG totals => Green=$green_total, Blue=$blue_total"
    exit 1
fi


cfstackparams=$(aws cloudformation describe-stacks --stack-name staging-dev-app-simplified --query 'Stacks[0].Parameters')

get_stack_param () {
    echo $cfstackparams | jq -r ".[] | select(.ParameterKey == \"$1\") | .ParameterValue"
}

newclrparams="$(get_stack_param "PreProdEnvironment${new_color}Weight")-$(get_stack_param "ProdEnvironment${new_color}Weight")"
oldclrparams="$(get_stack_param "PreProdEnvironment${old_color}Weight")-$(get_stack_param "ProdEnvironment${old_color}Weight")"

if [[ "$newclrparams" == "1-0" && "$oldclrparams" == "0-1" ]]; then
    echo "Cf stack parameter values are also ok."
else
    echo "Cf stack parameter values are not consistent with ASG values. $new_color Preprod-Prod = $newclrparams, $old_color Preprod-Prod = $oldclrparams"
    exit 1
fi

echo $old_color > ./old_color
echo $new_color > ./new_color

echo "Current color is $old_color. to be color is $new_color"
