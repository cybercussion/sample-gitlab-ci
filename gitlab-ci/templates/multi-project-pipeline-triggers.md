# Multi-Project Pipeline Trigger Example

In this concept you just need to gather the gitlab Project ID's and call out as many
downstream pipelines that you want.

```yml
# BVT multi-project pipelines

image: docker:latest

stages:
  - trigger

services:
  - docker:dind
 
# Need to add bash/curl support
before_script:
 - apk add --update curl && rm -rf /var/cache/apk/*

variables:
  GITLAB_URL: "https://yourdomain.com"
  BRANCH: "gitlab-ci-test"
  TEST_ENV: "dev"

# Template for CURL call for reuse
.curl: &curl
  # Restrict this from running using criteria
  only:
    - triggers
    - schedules
    - web
    - api
  script:
    - >-
        curl $GITLAB_URL/api/v4/projects/$PROJECT_ID/trigger/pipeline -X POST -k 
        -H "Content-Type: application/json"
        -d '
        {
            "token": "'"$CI_JOB_TOKEN"'",
            "ref": "'"$BRANCH"'",
            "variables": 
            {
                "RUN_BVT": "true",
                "TEST_ENV": "'"$TEST_ENV"'"
            }
        }'

# Trigger Each Service for BVT

# AddressService
address_service:
  tags:
    - aws-docker
  stage: trigger
  variables:
    PROJECT_ID: 35
  <<: *curl

# GCCService
gcc_service:
  tags:
    - aws-docker
  stage: trigger
  variables:
    PROJECT_ID: 822
  <<: *curl
    
# WorkerService
worker_service:
  tags:
    - aws-docker
  stage: trigger
  variables:
    PROJECT_ID: 48
  <<: *curl
```
