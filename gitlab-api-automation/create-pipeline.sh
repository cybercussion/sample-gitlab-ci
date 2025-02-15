#!/bin/bash

# This create a manual "Run Pipeline" by project, branch, and variable
# Remember this script is mainly done so we can promote by script if desired.
# Example: I want develop to promote to ENV or I want BRANCH in ENV.
# This is not meant to replace standard flow (GitOps) which already automatically generates
# pipelines.
# @requires GITLAB_TOKEN
# @usage sh create-pipeline.sh -a name-of-app -b branch -e ENV
# or
# @usage sh create-pipeline.sh -p 1988 -b branch -e ENV

. header.sh

# Deal with passing in -n name-of-app argument (and others)
while getopts p:a:e:b: option; do
case "${option}"
in
p) PROJ_ID=(${OPTARG});;  # this will overide PROJECTS array
a) APP_NAME=(${OPTARG});; # this will add a APP_NAME (name-of-app)
e) ENV=(${OPTARG});;      # this will add ENV (environment)
b) BRANCH=(${OPTARG});;   # this will add BRANCH (git branch)
esac
done

# Light error proofing
if [ -z $BRANCH ]; then
    echo "You are missing the '-b branch' argument or other branch name."
    exit 1
fi
if [ -z $ENV ]; then
    echo "You are missing the '-e ENV' argument or other environment."
    exit 1
fi

. shared-functions.sh

# If APP NAME was provided lets look up the Project ID (APP_NAME is not null)
if [ ! -z "$APP_NAME" ]; then
    echo "Searching for Project ID"
    gitlab_api_get_project_search $APP_NAME

    GITLAB_PROJECT_ID=$(jq -n "$RESULT" | jq -r --arg proj "$APP_NAME" '.[] | select(.name | contains($proj)) | .id')
    GITLAB_PROJECT_NAME=$(jq -n "$RESULT" | jq -r --arg proj "$APP_NAME" '.[] | select(.name | contains($proj)) | .name')
    if [ -z "$GITLAB_PROJECT_ID" ]; then
        echo "Sorry, was unable to locate a Project ID for $APP_NAME. Please try again"
        exit 1
    fi
    echo "$GITLAB_PROJECT_NAME identified $GITLAB_PROJECT_ID."
    PROJ_ID=$GITLAB_PROJECT_ID
fi

echo "$GITLAB_URL/projects/$PROJ_ID/pipeline for $ENV against $BRANCH"
#local PARAMS='{
    #    "ref": "'$BRANCH'",
    #    "variables": [
    #        {
    #            "key": "ENV",
    #            "value": "'$ENV'",
    #        }
    #    ]
    #}'
GITLAB_RESPONSE=$(curl -sS -X POST \
    -H "Content-Type: application/json" \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$PROJ_ID/pipeline" \
    -d "{\"ref\": \"$BRANCH\", \"variables\":[{\"key\": \"ENV\",\"value\": \"$ENV\"}]}")

echo $GITLAB_RESPONSE | jq