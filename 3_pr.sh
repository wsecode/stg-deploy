#!/bin/bash

if [[ -z $GITHUB_TOKEN ]] ; then
    echo 'Enter your GITHUB_TOKEN?'
    read GITHUB_TOKEN
fi

repo_with_org='innocraft/matomo-cloud'
from_branch='develop'
to_branch='staging'
pr_title='Update staging'
pr_body=''

# repo_with_org='ewikum/Hello-World'
# from_branch='test-1'
# to_branch='master'
# pr_title='Update staging'
# pr_body=''

resfile="res.$(date +%s)"
res_code=$(curl --write-out '%{http_code}' --silent --output $resfile \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    https://api.github.com/repos/$repo_with_org/pulls \
    -d "{\"title\":\"$pr_title\",\"body\":\"$pr_body\",\"head\":\"$from_branch\",\"base\":\"$to_branch\",\"draft\":false}")
res="$(cat $resfile)"
rm "$resfile"

pull_url=$(echo $res | jq -r '.url');

if [ "$res_code" -eq "201" ]; then
    mergeable=$(echo $res | jq -r '.mergeable')
    mergeable_state=$(echo $res | jq -r '.mergeable_state')

    echo "PR created. mergeable=$mergeable, mergeable_state=$mergeable_state"
    # printf '\e]8;;http://example.com\e\\This is a link\e]8;;\e\\\n'
    # open -n -a "Google Chrome" --args "$(echo $res | jq -r '.html_url')/files"
    echo "$(echo $res | jq -r '.html_url')/files"


    # if [[ -n $mergeable && -n $mergeable_state && $mergeable == "true" && $mergeable_state == "clean" ]]; then
        read -p "Check PR diff and press enter key to merge."
        echo "merging $pull_url"

        m_res_code=$(curl --write-out '%{http_code}' --silent --output /dev/null \
            -X PUT \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            $pull_url/merge \
            -d '{"merge_method":"merge"}')

        if [ "$m_res_code" -eq "200" ]; then
            echo 'Merged successfully.'
        else
            echo "Merge failed. $m_res_code"
            exit 1
        fi
    # fi


    exit 0
else
    echo "PR creation failed. $(echo $res | jq -r '.errors[].message')"
    exit 1
fi