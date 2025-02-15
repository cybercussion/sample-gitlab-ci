#!/bin/bash
# This is a script to setup protected branches by project id.
# in Settings -> Repository -> Protected Branches
# @requires GITLAB_TOKEN, curl, jq
# @usage sh setup-protected-branches.sh (or optionally) sh setup-protected-branches.sh -p "15445616"

. header.sh

# Deal with passing in -p "PROJECTID" (and others)
while getopts p: option; do
case "${option}"
in
p) PROJECTS=(${OPTARG});; # this will overide PROJECTS array
esac
done

# See http://vlabs.iitb.ac.in/gitlab/help/api/protected_branches.md
# This did not support a PUT or PATCH, have to DELETE and POST
# See: https://gitlab.com/gitlab-org/gitlab-foss/-/issues/37315
# Its not ideal, but its happening so fast it's a workaround.
set_protected_branches_by_id() {
    echo "\nSending protected branches request to Gitlab for $1\n"
    # GitFlow can sometimes use a develop branch.
    if [ "$DEVELOP_BRANCH" == "true" ]; then
        # Unprotect develop
        METHOD="DELETE"
        PROTECT_RES=$(curl -sS -X $METHOD \
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --url "$GITLAB_URL/projects/$1/protected_branches/develop")
        # Re Protect develop
        METHOD="POST"
        PROTECT_RES=$(curl -sS -X $METHOD \
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --url "$GITLAB_URL/projects/$1/protected_branches" \
        --data "name=develop&push_access_level=$NO_ACCESS&merge_access_level=$DEVELOPER&code_owner_approval_required=$CODE_APPROVAL")
    fi
    # Protect DEFAULT_BRANCH
    METHOD="DELETE"
    PROTECT_RES=$(curl -sS -X $METHOD \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$1/protected_branches/$DEFAULT_BRANCH")
    # Re Protect DEFAULT_BRANCH
    METHOD="POST"
    PROTECT_RES=$(curl -sS -X $METHOD \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$1/protected_branches" \
    --data "name=$DEFAULT_BRANCH&push_access_level=$NO_ACCESS&merge_access_level=$DEVELOPER&code_owner_approval_required=$CODE_APPROVAL")
}

# Safety check
if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    # Loop over projects
    for proj in ${PROJECTS[@]}; do
        set_protected_branches_by_id $proj
    done
fi