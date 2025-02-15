#!/bin/bash

# Moving methods that get reused here to keep things DRY.

# Search Gitlab Project(s) by name
# This may return an array of matches.
# Please pass in :name
# @usage gitlab_api_get_project_search name-of-project
# @returns RESULT
gitlab_api_get_project_search() {
    # https://docs.gitlab.com/ee/api/groups.html#list-a-groups-projects
    RESULT=$(curl -sS -X GET \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/groups/$GITLAB_GROUP_ID/projects" \
    --data "include_subgroups=true&search=$1")
}
# Taken from update-project.sh - need to sort out of this can occur in a loop
update_project() {
    echo "> I am going to edit $1 using approved configurations..."
    # https://docs.gitlab.com/ee/api/projects.html#create-project
    PROJ_RES=$(curl -sS -X PUT \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$1" \
    --data ci_default_git_depth=$PIPELINE_DEPTH \
    --data merge_method=$MERGE_METHOD \
    --data only_allow_merge_if_pipeline_succeeds=$MERGE_IF_PIPELINE_SUCCEEDS \
    --data allow_merge_on_skipped_pipeline=$MERGE_ON_SKIPPED \
    --data only_allow_merge_if_all_discussions_are_resolved=true \
    --data remove_source_branch_after_merge=true \
    --data default_branch=$DEFAULT_BRANCH)
    #--data shared_runners_enabled=true \ this is done at company (results in error)
    #--data-urlencode "build_coverage_regex=$CODE_COVERAGE" \ moving this to gitlab-ci makes sense by lang

    #echo "Result:"
    #echo "$PROJ_RES" | jq

    if [ -z "$PROJ_RES" ]; then
        echo "Something went wrong communicating with gitlab at $GITLAB_URL/projects/$1"
        exit 1
    fi
    # Name already taken
    if [ "$PROJ_RES" == "{\"message\":{\"name\":[\"has already been taken\"],\"path\":[\"has already been taken\"],\"limit_reached\":[]}}" ]; then
        echo "\nError: Name of this project is already taken and or flagged for deletion and is not available."
        exit 1
    fi
    # Tip: default_branch doesn't seem to stick, need to address downstream
    # web_url from response is viable for success
    # id from response returned for any further automation (Protected branches, etc ...)
    PROJ_ID=$(jq -n "$PROJ_RES" | jq -r '.id')
    PROJ_WEB_URL=$(jq -n "$PROJ_RES" | jq -r '.web_url')
    # Kick out if something else went wrong, couldn't get id (Hint: Check Gitlab just in case.)
    if [ -z "$PROJ_ID" ]; then
        echo "\nERROR: Something went wrong.  See below output from API:"
        echo "$PROJ_RES"
        exit 1
    fi
    echo "\n$PROJ_WEB_URL updated.\nTip: Hold down CTL or CMD click to open in browser.\n"

    PROJECTS=("$1") # Reset the PROJECTS Array!  Important when including 'source' below.
    sleep 5 # Need to give Gitlab a chance to fully copy the project before setting the default branch.
    # Tip: if you don't want any of these to block, put a & at the end.
    # [✔] set protected branch values, main, maybe develop
    source ./setup-protected-branches.sh
    # [✔] set push rules
    source ./setup-push-rules.sh
    # [✔] set default branch
    source ./setup-default-branch.sh
    # [✔] set environments (see setup-environments.sh)
    source ./setup-environments.sh
    # [✔] set ci variables (shared ones scoped to env)
    source ./setup-variables.sh
    # [✔] set approvals
    source ./setup-approvals.sh
    # TODO: set General Pipeline (shallow clone 10, artifact size 300MB)
    # [✔] set services
    source ./setup-services.sh
}