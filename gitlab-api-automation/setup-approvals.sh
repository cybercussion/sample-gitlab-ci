#!/bin/bash
# This will establish the Merge Request Approvals (min number to merge) and behaviors.
# This adjusts the Settings -> General -> Merge Request Approvals section
# @requires GITLAB_TOKEN, curl, jq
# @usage sh setup-default-branch.sh (or optionally) sh setup-default-branch.sh -p 1345546578

. header.sh

# Deal with passing in -n name-of-api argument (and others)
while getopts p: option; do
case "${option}"
in
p) PROJECTS=(${OPTARG});; # this will overide PROJECTS array
esac
done

# https://docs.gitlab.com/ee/api/merge_request_approvals.html#change-configuration
# This will enforce approval numbers and not allowing self-merge 
set_approvals_by_id() {
    echo "Sending merge approvals to Gitlab for $1"
    METHOD="POST"
    RES=$(curl -sS -X $METHOD \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$1/approvals" \
    --data "approvals_before_merge=$APPROVALS_BEFORE_MERGE&merge_requests_author_approval=$DISABLE_SELF_MERGE&disable_overriding_approvers_per_merge_request=$DISABLE_APPROVAL_OVERIDE")
    echo "done\n"
}

if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    # Loop over projects
    for proj in ${PROJECTS[@]}; do
        set_approvals_by_id $proj
    done
fi