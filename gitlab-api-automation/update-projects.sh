#!/bin/bash
# This will maintain a project by ID in GROUP_ID
# This takes the place of having to go thru all the menus after you've manually created a project.
# @requires GITLAB_TOKEN
# @usage sh update-project -p 16614568

. header.sh

# Deal with passing in -n name-of-project argument (and others)
while getopts g: option; do
case "${option}"
in
g) GITLAB_GROUP_ID=(${OPTARG});; # this will overide GROUPS array
esac
done

# Bring in shared 
. shared-functions.sh

# Make sure we got the basics.
if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    # This switches the pattern a bit with the other individual scripts which use the
    # PROJECTS array - originally a manually maintained list of IDs.
    # This sets the PROJECTS to a single project ID per loop for processing.
    gitlab_api_get_project_search
    GITLAB_PROJ_RES=$RESULT
    GITLAB_PROJ_LEN=$(jq -n "$GITLAB_PROJ_RES" | jq '. | length') # get the length
    GITLAB_PROJ_ID=$(jq -n "$GITLAB_PROJ_RES" | jq -r '.[] | .id')   # get a array of ids
    # Rest of the data in this RESULT is not needed, just need to loop over id's
    echo "Total Projects: $GITLAB_PROJ_LEN"
    if [ "$GITLAB_PROJ_LEN" -gt 1 ]; then
        # Loop over items in array
        for proj_id in ${GITLAB_PROJ_ID[@]}; do
            echo "\n-------------"
            update_project $proj_id
        done
    else
        echo "Sorry, no projects were available in $GROUP_ID."
        exit 1
    fi
fi
