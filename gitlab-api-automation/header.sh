#!/bin/bash

# This controls entry point to scripts if we need to load in vars.sh
if [ -z "$GITLAB_DOMAIN" ]; then
    echo "$GITLAB_DOMAIN - not set, including vars."
    . vars.sh # Bring in shared vars
fi
