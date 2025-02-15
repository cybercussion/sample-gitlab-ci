#!/bin/bash
# This will establish push rules for the projects
# This takes the place of hitting Settings -> Repository -> Push Rules
# @requires GITLAB_TOKEN, curl, jq
# @usage sh setup-push-rules.sh (or optionally) sh setup-push-rules.sh -p "13446545"

. header.sh

# Deal with passing in -p name-of-api argument (and others)
while getopts p: option; do
case "${option}"
in
p) PROJECTS=(${OPTARG});; # this will overide PROJECTS array
esac
done

#https://docs.gitlab.com/ee/api/projects.html#edit-project-push-rule
# Tip: You have a POST for a new ( will throw error if exists )
#      You have a PUT for a edit ( failover if error above occurs )
set_pushrules_by_id() {
    echo "\nSending push rules request to Gitlab for $1\n"
    METHOD="POST"
    CREATE_RES=$(curl -sS -X $METHOD \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$1/push_rule" \
    --data "commit_message_regex=$PUSH_RULES" \
    --data "prevent_secrets=true" \
    --data "reject_unsigned_commits=false" \
    --data "commit_committer_check=false" \
    --data "max_file_size=0" \
    --data "member_check=false")
    # if POST doesn't work you'll get back {"error":"Project push rule exists"}.  Newest one says message not error.
    # We then need to check this, and do a PUT
    if [ "$CREATE_RES" == "{\"message\":\"Project push rule exists\"}" ]; then
        echo "Prior push rule exists, updating..."
        METHOD="PUT"
        CREATE_RES=$(curl -sS -X $METHOD \
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --url "$GITLAB_URL/projects/$1/push_rule" \
        --data "commit_message_regex=$PUSH_RULES" \
        --data "prevent_secrets=true" \
        --data "reject_unsigned_commits=false" \
        --data "commit_committer_check=false" \
        --data "max_file_size=0" \
        --data "member_check=false")
        echo 'done\n'
    fi
}

if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    # Loop over projects
    for proj in ${PROJECTS[@]}; do
        set_pushrules_by_id $proj
    done
fi