#!/bin/bash
# This is a script to scan for environments by project id for GROUP_ID
# Only use this if you are using gitlab-ci as it will sync your environment pipelines so you obtain at-a-glance views
# in Operations -> Environments
# @requires GITLAB_TOKEN
# usage sh setup-environments.sh (or optionally) sh setup-environments.sh -p "154645678"

. header.sh

# Deal with passing in -p "PROJECTID" (and others)
while getopts p: option; do
case "${option}"
in
p) PROJECTS=(${OPTARG});; # this will overide PROJECTS array
esac
done

# Create Environment
create_environment() {
    echo "Sending create request to Gitlab for $1 setting up $2"
    #LAB_LOWER=${2,}
    CREATE_RES=$(curl -sS -X POST \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --url "$GITLAB_URL/projects/$1/environments" \
    --data "name=$2&external_url=")
}
# Get Environment By Project id
# This will loop over labs in Gitlab on a project and compare them to the expected lab for validation.
# This will use the expected $LABS to validate and or create whats missing.
get_environments_by_id() {
    if [ -z "$1" ]; then # verify we have a id
        echo "Please supply a id to search for. 🔍"
    else
        echo "\n>> Evaluating project $1"
        RES=$(curl -sS -X GET \
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --url "$GITLAB_URL/projects/$1/environments")
        # Evaluate Result for Validity (maybe harden this later to make it better)
        if [ "{\"message\":\"401 Unauthorized\"}" == "$RES" ]; then
            echo "ERROR: Please check your Gitlab Token, you are currently unauthorized! 🔑"
            echo $RES
        else
            # printf '%s\n' "${ENV_ARR[@]}"
            ENV_ARR=( $(jq -n "$RES" | jq -r '.[].name') ) # This is a bash array
            # This compares what we get to what we expect, having something we didn't may require you to take action.
            for lab in ${ENV_ARR[@]}; do                   # Loop over bash array
                if [[ "${LABS[@]}" =~ "$lab" ]]; then      # Check if lab is expected
                    echo "    ✔ $lab"
                    ((TOTAL_LABS+=1))
                else
                    echo "    x Warning: $lab - not expected!"
                fi
            done
            # This is the option to create whats missing, compare counts, then execute.
            if [ "$TOTAL_LABS" -eq "0" ]; then
                echo "\nThis looks like a new project.  Lets create the Labs if there are any!\n"
                for lab in ${LABS[@]}; do                     # No Match
                    create_environment $1 $lab
                done
                echo "done\n"
            elif [ "${#ENV_ARR[@]}" -eq "$TOTAL_LABS" ]; then # 100% MaTCH
                echo "🍺 Labs looking good in Gitlab. 👍"
            elif [ "$TOTAL_LABS" -lt "${#LABS[@]}" ]; then    # Partial Match
                echo "\nLab Checkup: We had a mis-match, double checking...\n"
                for lab in ${LABS[@]}; do
                    if [[ "${ENV_ARR[@]}" =~ "$lab" ]]; then  # Check if lab is expected
                        echo "✔ Env: $lab"
                    else
                        echo "x Env: $lab - not created!  Kicking off request to create it..."
                        create_environment $1 $lab
                    fi
                done
            else
                echo "\nWARNING: You may want to review excess labs in this environment!\n"
            fi
        fi
    fi
}

if [ -z "$GITLAB_TOKEN" ]; then
    echo "Please set your GITLAB_TOKEN!! 🤬 \nhint: export GITLAB_TOKEN=<URTOKEN>"
else
    # Loop over projects
    for proj in ${PROJECTS[@]}; do
        TOTAL_LABS=0 # reset
        get_environments_by_id $proj
    done
    echo ""
fi
