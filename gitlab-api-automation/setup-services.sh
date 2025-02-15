#!/bin/bash
# This will create service integrations with Jira, Slack, Teams or other
# This adjusts the Settings -> Integrations
# See API availability at https://docs.gitlab.com/ee/api/services.html
# @requires GITLAB_TOKEN, curl, jq
# @usage sh setup-services.sh (all, or optionally) sh setup-services.sh -p 1345

. header.sh

# Deal with passing in -p name-of-api argument (and others)
while getopts p: option; do
case "${option}"
in
p) PROJECTS=(${OPTARG});; # this will overide PROJECTS array
esac
done

# Get Services
# Not sure if this will be used but it should return back all services.
# Note: could be disabled in this script. See bottom of file.
# Gitlab has renamed service to integration
get_services() {
    local SERVICES_RES=$(curl -sS -X GET \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$1/integrations")
    # Pretty Print to log
    echo $SERVICES_RES | jq
}

# Set Service
# This will take care of interactions with Gitlab API and deal with PUT or GET/PUT
# This is for internal use but you could use it like its implemented in Jira, Slack
# MSTeams below.
# @usage set_service $METHOD $PROJECT_ID $SERVICE $PARAMS
set_service() {
    echo "\nSetting service $3 in Gitlab using $1\n"
    # Convert Passed Parameters to QueryString
    # echo $4 | jq
    local PARAMS=$(jq -n "$4" | jq -r 'to_entries|map("\(.key)=\(.value|tostring)") | join("&")')
    local SERVICE_RES=$(curl -sS -X $1 \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$2/integrations/$3" \
    --data "$PARAMS")
    echo "Service Result:"
    echo $SERVICE_RES | jq
}

# GET, PUT, DELETE /projects/:id/services/jira
set_service_jira_by_id() {
    echo "\nSending service Jira request to Gitlab for $1\n"
    # This is setup to use the apii-variables.json where the JSON is set.
    # Alternative
    #local JIRA_PARAMS='{
    #    "url": "'$JIRA_URL'",
    #    "username": "'$JIRA_USERNAME'",
    #    "password": "'$JIRA_PASSWORD'",
    #    "jira_issue_transition_id": "'$JIRA_TRANSITIONS'",
    #    "commit_events": true,
    #    "merge_requests_events": true,
    #    "comment_on_event_enabled": true
    #}'
    # or pull it from config file (JSON)
    local PARAMS=$(jq -n "$CI_VARS" | jq -r '.services[] | select(.name == "jira") | .data')
    #echo "$JIRA_PARAMS" | jq
    local METHOD="PUT"

    set_service "$METHOD" "$1" "jira" "$PARAMS"
}

# GET, PUT, DELETE /projects/:id/services/jira
set_service_confluence_by_id() {
    echo "\nSending service Confluence request to Gitlab for $1\n"
    # This is setup to use the apii-variables.json where the JSON is set.
    # Alternative
    #local JIRA_PARAMS='{
    #    "confluence_url": "'$CONFLUENCE_URL'",
    #}'
    # or pull it from config file (JSON)
    local PARAMS=$(jq -n "$CI_VARS" | jq -r '.services[] | select(.name == "confluence") | .data')
    #echo "$JIRA_PARAMS" | jq
    local METHOD="PUT"

    set_service "$METHOD" "$1" "confluence" "$PARAMS"
}

# GET, PUT, DELETE /projects/:id/services/slack

set_service_slack_by_id() {
    echo "\nSending service Slack request to Gitlab for $1\n"
    # This is setup to use the apii-variables.json where the JSON is set.
    #local SLACK_PARAMS='{
    #    "webhook": "'$SLACK_WEBHOOK'",
    #    "username": "'$SLACK_USERNAME'",
    #    "channel": "",
    #    "notify_only_broken_pipelines": false,
    #    "notify_only_default_branch": false,
    #    "branches_to_be_notified": "all",
    #    "commit_events": false,
    #    "confidential_issue_channel": false,
    #    "confidential_issues_events": false,
    #    "confidential_note_channel": false,
    #    "confidential_note_events": false,
    #    "deployment_channel": "",
    #    "deployment_events": true,
    #    "issue_channel", "",
    #    "issues_events", false,
    #    "job_events": false,
    #    "merge_request_channel": false,
    #    "merge_requests_events": false,
    #    "note_channel": "",
    #    "note_events": false,
    #    "pipeline_channel": "",
    #    "pipeline_events": false,
    #    "push_channel": "",
    #    "push_events": false,
    #    "tag_push_channel": "",
    #    "tag_push_events": false,
    #    "wiki_page_channel": "",
    #    "wiki_page_events": false
    #}'
    local PARAMS=$(jq -n "$CI_VARS" | jq -r '.services[] | select(.name == "slack") | .data')
    local METHOD="PUT"
    set_service "$METHOD" "$1" "slack" "$PARAMS"
}

# GET, PUT, DELETE /projects/:id/services/microsoft-teams
set_service_msteams_by_id() {
    echo "\nSending MS Teams request to Gitlab for $1\n"
    # This is setup to use the apii-variables.json where the JSON is set.
    #local MSTEAMS_PARAMS='{
    #    "webhook": "'$MSTEAMS_WEBHOOK'",
    #    "notify_only_broken_pipelines": true,
    #    "branches_to_be_notified": "all",
    #    "push_events": false,
    #    "issues_events": false,
    #    "confidential_issues_events": false,
    #    "merge_requests_events": true,
    #    "tag_push_events": true,
    #    "note_events": false,
    #    "confidential_note_events": false,
    #    "pipeline_events": true,
    #    "wiki_page_events": false
    #}'
    local PARAMS=$(jq -n "$CI_VARS" | jq -r '.services[] | select(.name == "microsoft-teams") | .data')
    local METHOD="PUT"
    set_service "$METHOD" "$1" "microsoft-teams" "$PARAMS"
}

if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    # Loop over (managed) projects - Remember if you pass in a single project, it will only do one.
    if [ -f "$VARIABLES_FILE" ]; then # Check if file exists ( May be worth doing this earlier )
        if [ -z "$CI_VARS" ]; then
            CI_VARS=$(jq . $VARIABLES_FILE) # Load the file once if not already
        fi
        for proj in ${PROJECTS[@]}; do
            echo "Looping over services..."
            #get_services $proj
            #set_service_jira_by_id $proj
            set_service_confluence_by_id $proj
            #set_service_slack_by_id $proj
            #set_service_msteams_by_id $proj
            #other?
        done
    else
        echo "Warning: You are missing a needed $VARIABLES_FILE file for setting up Service Integrations!"
        # exit 1
    fi
fi
