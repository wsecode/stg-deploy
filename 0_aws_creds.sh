#!/bin/bash
export AWS_ACCESS_KEY_ID="ASIAS5ZBVLOWUQG7PU5A"
export AWS_SECRET_ACCESS_KEY="YKcun8a9y+FPIFdy/9g3aqvaIWVPx/LcU79jHy6q"
export AWS_SESSION_TOKEN="IQoJb3JpZ2luX2VjEHkaDGV1LWNlbnRyYWwtMSJGMEQCIBKoGXAi1GE5pCdnbPR1foLCQwgfkpJ+guk7kva+NCzbAiA7NfTbxizD/ny9F9a98u98iq5AiiWY6ajypJIK92h+ziqEAwii//////////8BEAQaDDIwMTM5NzE5Nzc0MSIM9Tz9JcnxlnQSFoWOKtgCm6IsS2SL08ewB+EEWVIM85WgO2PMJQbTGIFY6/utexGCzGF8w6UegXoZKPCwu/ccSefqt9slT8o+sjhYJzLdIIrNlWvwvEZLkXfDMsMLYv0eLje24V0Lb5dRw/Gme5rRZLeu7BXJR3t7Tt7TzNPhRTiyJc1tdu0PWy/K8cdn5deu/SUn2nB4p2SiiYtahIfNmMvTqy4Bxs6AQcBelauHszsQS6WISNrsgoeZaGk02BGNDc/JcvHxyEvujKNmBquj1vC5mWJ6ePF5TLjhyr4tAGJ7egZOiQNtJJCgvWukOD4VjR9ZAadT1lU/Ij+QXfWkBKs+VBOUIoLiOeA7usFa64kXF8Akz0cBYDp8g6E8IP4KL1IeBotx/WPCdfVO8TrY6kOL8RbA8Ijb2e1gP4OTGzYTulIsoOOTAPhbffyAs/iap1BGQ3xH2W+bcmqahYkGLB8p6bamnMUw8NzbnAY6qAFlCNmy1yB0JN7NbU7a+MRFHDx2tdYBNLM/DDwthUtzqbGsV6CdC1YBn+pK8STlXck/iDIa9W+J0KNPXQtQrhxWG3uDcu58hNYxTdF8jUWd+Qqyg6BmIU/y29a0QV1g3iZFsoTDib9QRQELtzHwxoJZsNtTeetwnWMT8lMrArMGLr2eT/GGnKjvlcRuTPnxjlbJWpeGVuBuSfWRmRgqB2QRThlikykc81M="


export AWS_DEFAULT_REGION="eu-central-1"

aws_account_id=$(aws sts get-caller-identity --query 'Account' | jq -r)

if [[ $aws_account_id -ne "201397197741" ]]; then
    echo "Wrong AWS account: $aws_account_id"
    exit 1
fi