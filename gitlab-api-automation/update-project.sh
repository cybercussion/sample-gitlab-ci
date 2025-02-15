#!/bin/bash
# This will maintain a project by ID in GROUP_ID
# This takes the place of having to go thru all the menus after you've manually created a project.
# @requires GITLAB_TOKEN
# @usage sh update-project -p 16614568

. header.sh

# Deal with passing in -n name-of-project argument (and others)
while getopts p: option; do
case "${option}"
in
p) PROJECTS=(${OPTARG});; # this will overide PROJECTS array
esac
done

. shared-functions.sh

# Make sure we got the basics.
if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    # Kick it off
    update_project "${PROJECTS[0]}"
fi
