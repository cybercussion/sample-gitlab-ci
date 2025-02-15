#!/bin/bash
# This will establish a named project in the GROUP_ID from a designated template.
# This takes the place of hitting [New Project], Setting a description, picking a template, and hitting create.
# @requires GITLAB_TOKEN
# @usage sh create-project -n name-of-project

. header.sh

APP_NAME=""                # Replaced with -n argument

# Deal with passing in -n name-of-api argument (and others)
while getopts n: option; do
case "${option}"
in
n) APP_NAME=${OPTARG};;
esac
done

create_project() {
    echo "> I am going to create $1 using approved configurations..."
    # https://docs.gitlab.com/ee/api/projects.html#create-project
    PROJ_RES=$(curl -sS -X POST \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/" \
    --data "name=$APP_NAME&namespace_id=$GITLAB_GROUP_ID&merge_method=$MERGE_METHOD&shared_runners_enabled=true&only_allow_merge_if_pipeline_succeeds=true&only_allow_merge_if_all_discussions_are_resolved=true&remove_source_branch_after_merge=true&use_custom_template=true&template_project_id=$GITLAB_TEMPLATE_ID&default_branch=$DEFAULT_BRANCH&description=Automated&ci_default_git_depth=$PIPELINE_DEPTH&build_coverage_regex=$CODE_COVERAGE")
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
    echo "\n$PROJ_WEB_URL created.\nTip: Hold down CTL or CMD click to open in browser.\n"
    echo "Please add \"$PROJ_ID\" to the vars.sh PROJECTS array in order to maintain it in the future.\n"
    echo "\nTaking a rest, letting project template copy...\n"
    PROJECTS=("$PROJ_ID") # Reset the PROJECTS Array!  Important when including 'source' below.
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
    # TODO: set General Pipeline (shallow clone 0, artifact size 300MB)
    # [✔] set services
    source ./setup-services.sh
    GITLAB_DOMAIN="" # wipe this out to encourage the system to reload vars the next time. (Reset the forced PROJECTS above)
}

# Make sure we got the basics.
if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    if [ -z "$APP_NAME" ]; then
        echo "ERROR: you did not pass a app name!"
    else
        # Kick it off
        create_project $APP_NAME
    fi
fi
