#!/bin/bash
# This will set basic CI / CD Variables
# This would replicate Settings -> CI / CD -> Variables (Project Level Variables)
# This will only entery universal values from a file.
# anything with "SECRET" or "KEY" or "TOKEN" in the name will be Masked.
# Tip: Remember 'protected' just means protected branches will only get the variable (like main).
# @requires GITLAB_TOKEN
# @usage sh setup-variables.sh -p 1466456

. header.sh

# Deal with passing in -n name-of-api argument (and others)
while getopts p: option; do
case "${option}"
in
p) PROJECTS=(${OPTARG});; # this will overide PROJECTS array
esac
done

set_variables() {
    # Loop over keys in Lab
    for k in $(jq -n "$CI_VARS" | jq -r --arg lab "$lab" '.[$lab] | keys[]'); do
        echo "would $3 $1 $k for $2"
        SCOPE=$2
        MASKED="false" # this is tricky due to its value (some can't be masked)
        PROTECTED="false" # Protected should really only be for PROD (DEFAULT) branch.
        # Loop over MASK array to see if substring exists
        for SUB in ${MASK_SUB[@]}; do
            if [[ "$k" =~ .*"$SUB".* ]]; then
                MASKED="true"
            fi
        done
        if [ "$SCOPE" == "ALL" ]; then
            SCOPE="*" # Wild card for All environments
        fi
        VALUE=$(jq -n "$CI_VARS" | jq -r --arg lab "$lab" --arg k "$k" '.[$lab][$k]')
        # We wll attempt to POST, but then fail over to enforcement of the value from your ~/variables.json file.
        VAR_RES=$(curl -sS -X POST \
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --url "$GITLAB_URL/projects/$1/variables" \
        --data "key=$k&value=$VALUE&variable_type=env_var&masked=$MASKED&environment_scope=$SCOPE")

        echo $VAR_RES
        if [ "VAR_RES" == "{\"message\":{\"key\":[\"($k) has already been taken\"]}}" ]; then
            # This would need to change to a PUT/PATCH
            echo "$k has already been set, needs to be updated manually."
        fi
    done
    echo $LAB_VARS
}
# Managing Variables is a bit more involed due to adding, updating or removing.
# It will also require parsing a JSON file and then posting these.
# If its a edit, it will need to get the id, then PUT.
# You can merge JSON objects with - jq -s '.[0] * .[1]' file1 file2
set_variables_by_id() {
    if [ -f "$VARIABLES_FILE" ]; then # Check if file exists ( May be worth doing this earlier )
        if [ -z "$CI_VARS" ]; then
            CI_VARS=$(jq . $VARIABLES_FILE) # Load the file once
        fi
        # We need to loop thru LABS, and pull each lab out of the JSON.
        # But because we have a special "ALL" category, we will copy the labs array and add "ALL to it.
        UPDATED_LABS=("${LABS[@]}" "ALL") # create new array
        for lab in ${UPDATED_LABS[@]}; do
            set_variables $1 $lab
        done
    else
        echo "Warning: You are missing a needed $VARIABLES_FILE file for setting up CI Variables!\n"
        # exit 1
    fi
}

if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    # Loop over projects
    for proj in ${PROJECTS[@]}; do
        set_variables_by_id $proj
    done
fi
