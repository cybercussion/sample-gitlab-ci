#!/bin/bash
# Tip: If you get into a situation where a lower script adjusts variables you may need to close/re-open your window.
# Remember this project is meant to mirror your desired flow with Gitlab and may considered team best practices.
# This will allow you to propagate these changes out to an array of PROJECT ID's or look them up by group.
# For mulitple groups you may need to adjust this with a group array.

GITLAB_DOMAIN="https://gitlab.com"
GITLAB_API_VERSION="/api/v4"
GITLAB_URL="$GITLAB_DOMAIN$GITLAB_API_VERSION"
CRED=~/.gitlab/credentials.json # Don't wrap with quotes, breaks jq load

# Expected Lab Array
LABS=() # Edit as needed i.e. dev, staging, preview, prod - if you have CI Variables that need prefixing
TOTAL_LABS=0

# Edit the below to match your needs.
# GROUP_ID=""                    # GROUP ID surrounding projects for automation
# TEMPLATE_ID=""                 # TBD, for use with creation from single template
DEVELOP_BRANCH="false"           # GitFlow and other Branching strategies may have a develop branch
DEFAULT_BRANCH="main"            # Mainline branch name
MERGE_METHOD="merge"                # fast-forward (ff), merge, rebase_merge
CODE_APPROVAL="true"             # Code owner approval
CODE_COVERAGE=""                 # Code Coverage Regex pattern (differs from languages) - evaluate unit test/code cov format in log.
# Note: May want to add the 'coverage:' block in a CI Job to set this.
# Maven: Application Coverage.*?([0-9]+.[0-9]+)%
# Python: /TOTAL.*\s+(\d+\%)/
# JavaScript/Jest: /All\sfiles.*?\s+(\d+.\d+)/ or ^(?:Statements|Branches|Functions|Lines)\s*:\s*([^%]+)
APPROVALS_BEFORE_MERGE="1"       # Number of approvals for merge
MERGE_IF_PIPELINE_SUCCEEDS="true"
MERGE_ON_SKIPPED="false"
DISABLE_SELF_MERGE="false"       # Disable person from self-merging false = enabled, true = disabled
DISABLE_APPROVAL_OVERIDE="false" # Disable someone turning it off false = enabled, true = disabled
PUSH_RULES="(i?)([Jj][Ii][Rr][Aa][-])[0-9]{1,5}|(i?)Merge branch" # Ticket format and Cover Merge commits (stops fix, test commits w/o context)
PIPELINE_DEPTH=10                # default is 50, this makes checkouts faster
ARTIFACT_SIZE=100                # default is commonly 100, increase if you have larger zips
VARIABLES_FILE=~/company/variables.json # this is optional, it will not run if it doesn't exist
# Gitlab Access Levels
NO_ACCESS="0"
ADMIN="60"
MAINTAINER="40"
DEVELOPER="30"
# Mask Variables (This will automatically mask CI Variables)
MASK_SUB=("KEY" "TOKEN" "SECRET")
# End Edit

# Create dot folder and credentials file.
make_cred_file() {
    $(mkdir ~/.gitlab)
    CRED_FILE="{\n\
    \"url\": \"$GITLAB_DOMAIN\",\n\
    \"token\": \"PUT YOUR TOKEN HERE\"\n\
}"
    $(echo "$CRED_FILE" > ~/.gitlab/credentials.json)
}

# Verify cURL support
if [ -x "$(command -v curl)" ]; then
    echo "✔ curl"
else
    echo "ERROR: Sorry, you do not have curl support.  You may have a '<package manager> install curl' command you can use.\n"
    echo "Mac users I'd install homebrew, and run 'brew install curl'"
    echo "Windows users git bash has curl, ubuntu bash may just need to install it `apt-get install curl`"
    exit 1
fi
# Verify jq support
if [ -x "$(command -v jq)" ]; then
    echo "✔ jq"
else
    echo "ERROR: Sorry, you do not have jq support.  You may have a '<package manager> install jq' command you can use.\n"
    echo "Mac users I'd install homebrew, and run 'brew install jq'."
    echo "Windows users see https://stackoverflow.com/questions/53967693/how-to-run-jq-from-gitbash-in-windows"
    exit 1
fi

# Check if Token alrTready exists, else load or create
load_cred_file() {
    if [ -z "$GITLAB_TOKEN" ]; then # Cred maybe already set
        GITLAB_TOKEN=$(jq -r .token $CRED) # Cred not set, try to load it from file
        if [ -z "$GITLAB_TOKEN" ]; then # Failure
            make_cred_file # Help user make a file we told them to make
            echo "\nERROR: credentials file not found, and GITLAB_TOKEN not set... 🤬"
            echo "Please go generate your Gitlab Token! CTL/CMD + CLICK below:"
            echo "$GITLAB_DOMAIN/profile/personal_access_tokens" # Help user know where to go .. rest up to them
            echo "\nThen, open '$CRED', and add your token.\nHint: its a dot file (hidden), show all files/folders.\n"
            echo "-- Windows you can use the command \"explorer ~/\" to open this via CLI."
            echo "-- Mac you can do this via \"open $CRED\" to open in default editor."
            echo "-- Linux, you probably know how to do this, else you wouldn't be on Linux ;).\n"
            exit 1 # Kick out, let them do this.
        fi
    fi
    echo "\n🔑 Gitlab Token loaded.\n"
}

load_cred_file
