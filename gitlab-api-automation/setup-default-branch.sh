#!/bin/bash
# This will establish the default branch for the GROUP_ID
# This takes the place of hitting Settings -> Repository -> Default Branch
# @requires GITLAB_TOKEN, curl, jq
# @usage sh setup-default-branch.sh (or optionally) sh setup-default-branch.sh -p 134554654

. header.sh

# Deal with passing in -n name-of-api argument (and others)
while getopts p: option; do
case "${option}"
in
p) PROJECTS=(${OPTARG});; # this will overide PROJECTS array
esac
done

#https://docs.gitlab.com/ee/api/projects.html#edit-project-push-rule
# Tip: You have a POST for a new ( will throw error if exists )
#      You have a PUT for a edit ( failover if error above occurs )
set_defaultbranch_by_id() {
    echo "Sending default branch request to Gitlab for $1"
    METHOD="PUT"
    RES=$(curl -sS -X $METHOD \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$1" \
    --data "default_branch=$DEFAULT_BRANCH")
    if [ "$RES" == "{\"message\":{\"base\":[\"Could not change HEAD: branch '$DEFAULT_BRANCH' does not exist\"]}}" ]; then
        echo "WARNING: This project is missing the branch $DEFAULT_BRANCH, please create it."
        echo "It's possible you created a project or used a template without this branch."
        echo "This script does not know what branch you want to create it from."
        echo "After its created, you can re-run this 'sh setup-default-branch.sh -p $1'.\n"
    fi
}

if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    # Loop over projects
    for proj in ${PROJECTS[@]}; do
        set_defaultbranch_by_id $proj
    done
fi