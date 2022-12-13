#!/bin/bash
. ./0_aws_creds.sh

# aws cloudformation describe-change-set --change-set-name arn:aws:cloudformation:eu-central-1:201397197741:changeSet/staging-change-set-1670836550/d8ce02c6-6370-404d-bc1d-e1b9152d99d9 | jq

# exit

new_color=$(cat ./new_color)
old_color=$(cat ./old_color)
change_set_name="staging-change-set-$(date +%s)"

changesetout=$(aws cloudformation create-change-set --stack-name staging-dev-app-simplified --change-set-type UPDATE --use-previous-template \
--change-set-name "$change_set_name" \
--capabilities CAPABILITY_IAM \
--parameters \
ParameterKey="ProdEnvironment${new_color}Weight",ParameterValue="1" \
ParameterKey="ProdEnvironment${old_color}Weight",ParameterValue="0" \
ParameterKey="CDNDomain",UsePreviousValue=true \
ParameterKey="CloudFrontDistributionId",UsePreviousValue=true \
ParameterKey="AssetsBucketName",UsePreviousValue=true \
ParameterKey="SupportNotificationTopics",UsePreviousValue=true \
ParameterKey="LogGroupName",UsePreviousValue=true \
ParameterKey="DNSPrefix",UsePreviousValue=true \
ParameterKey="ALBAC3ServiceId",UsePreviousValue=true \
ParameterKey="ConfigSecretName",UsePreviousValue=true \
ParameterKey="BlueParameterStoreID",UsePreviousValue=true \
ParameterKey="Environment",UsePreviousValue=true \
ParameterKey="EFSFileSystem",UsePreviousValue=true \
ParameterKey="InternalNotificationTopic",UsePreviousValue=true \
ParameterKey="SesSmtpSecretName",UsePreviousValue=true \
ParameterKey="DatabaseSG",UsePreviousValue=true \
ParameterKey="WebASGAC3ServiceId",UsePreviousValue=true \
ParameterKey="ArchivingASGAC3ServiceId",UsePreviousValue=true \
ParameterKey="GreenParameterStoreID",UsePreviousValue=true \
ParameterKey="EFSSecurityGroup",UsePreviousValue=true \
ParameterKey="AlbAccessLogsBucketName",UsePreviousValue=true \
ParameterKey="TrackingASGAC3ServiceId",UsePreviousValue=true \
ParameterKey="ArtifactsBucketName",UsePreviousValue=true \
ParameterKey="CachedDNS",UsePreviousValue=true)

changesetarn=$(echo $changesetout | jq -r '.Id')

echo "Change set $changesetarn created.";

check_changeset_states () {
    local status=$(aws cloudformation describe-change-set --change-set-name $1 --query 'Status' | jq -r)
    echo $status
    if [[ $status == "CREATE_COMPLETE" ]]; then
        return 0
    else
        return 1
    fi
}

while sleep 2; do 
    echo "Checking change set status... $(date)"
   if check_changeset_states $changesetarn ; then
        echo "Change set is Ok!"
        break
    fi
    printf "\033[2A"
done

exit;



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
