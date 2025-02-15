# Gitlab API Shell Scripts

The `GITLAB_TOKEN` permission level matters.  If you attempt to run this against projects you do not have access tokens permission against, it will result in 404 errors.  If you do not have the permission to get a access token in a group you'd need to ask a Owner for that permission.
I do not recommend anyone use their own personal access tokens on their account with Gitlab as those relying on it may fail if you switch accounts or expire your tokens.

These are generally setup to work off known projects, via established arrays in `vars.sh`.  Please read any
`@usage` in any of the files for tips on how to use them individually.  Some offer extending arguments to get some
added capabilities to do single projects, or an array of projects.  Other configurations are in a `VARIABLES_JSON` file.  Covered below.

See https://docs.gitlab.com/ee/api/ for more detailed breakdowns on Gitlab's API.

Make sure if you are a Owner/Maintainer you've set up a Gitlab Access Token (currently mwa-templates).
This can be overwritten by passing a `GROUP_ID` CI Variable in a custom pipeline.  But note that the access token matters.
If expanding this please update the GITLAB_TOKEN, or consider forking this project.

## Why do it like this?

Gitlab has a rich REST based API. For the most part all the sections we have to edit (repeatedly) is rather time consuming.
Also there can be some drift and you may need to enforce, or tune many projects.  Since it is a REST API there are several cases where you have to do a POST or a PUT (new vs update) and these scripts attempt to combat some of that.
This is setup using shell scripting as a least-friction based way to automate without needing extra stuff beyond bash/curl/jq.
So (example) situations where you decide to change from Merge Commits to Fast-Forward can no be automated so you would not need to go project by project to make the change.

## If running local - Token Option (or see below credentials.json file)

```bash
export GITLAB_TOKEN=<your token>
```

Fail to do this, you have the below option...

## vars

A `vars.sh` file will house some basic shared variables and values.  These will be loaded into other files via `. vars.sh`  If you are using this file/project outside the scope of `Group 1 / Group 1 / templates` you may need a new Gitlab Access Token for the group.

For local use, this will now also attempt to load a `~/.gitlab/credentials.json` file and or create it if you didn't do this or locally set your GITLAB_TOKEN.  You can alternatively use your own access tokens on your profile, or a access token at a group/project level.

```json
{
    "url": "https://gitlab.com",
    "token": "Your token here"
}
```

**Please see example JSON file below for managing variables, services or other needs.  This uses the `VARIABLES_FILE` contained within vars.sh**

`PROJECTS` was originally a manual array of projects to run these scripts against.  This was manually maintained in `vars.sh`.  I favored looking at it by GROUP_ID in `update-projects.sh` but there may be a use case later to specify many GROUP_IDs.  If you encounter that it could be wrapped better.

## create-project (TBD)

>This is a chain reaction script

Designed to implement the creation of a named project off a template.  If you make something by accident, you'll need to go
into Gitlab and remove it under the project, settings, General, Remove.  Sorry, no CMD/CTL+Z.

`sh create-project.sh -n name-of-app`

## update-project

For manually created projects you can use the command:

`sh update-project.sh -p 1661` and obtain your gitlab project id from Gitlab.  This will do everything that the create-project does.

## update-projects

`sh update-projects.sh -g 3456`
For projects in a group (including sub groups) will loop over and apply to all
### What will this do?

* Create a Project (TBD - intent is to use a create new Project from template)
* Use a template (one of mwa-templates) which comes pre-configured with files/branches.
* Sets default branch to 'main'.
* Sets Merge Request settings based on those settings in `vars.sh`.
* Sets Protected Branches (main) or other.
* Sets push rules to match Jira ticket types (for better integration)
* Sets environments?  (If your using CI Variables per environment this would be needed)
* Sets your approvals strategy.
* Sets Pipeline shallow clone level, and artifact size (TBD)
* Sets basic CI Variables
* Sets Service integrations (Jira, MSTeams, Confluence, Slack or *)

Individual scripts can be used as-needed in the event someone created something manually or did not configure or you've altered your approach and want to propagate changes to all or a single project.

# Following were designed for single use via local cmdline

These are the individual parts incase you need to apply just one part of the change vs enforcing it all.
## Default Branch

This will establish the `DEFAULT_BRANCH` referenced in `vars.sh`.

If it doesn't exist, it can't make it.  So you'll see a warning if that happens.  Recently I see it show as a deleted branch so this has changed since originally authored.

### Audit/Enforce all projects

`sh setup-default-branch.sh` -- Loops over all your `PROJECTS`.

### Audit/Enforce single project

`sh setup-default-branch.sh -p 1455` -- know your project id or be prepared for it to loop over all your `PROJECTS`.

## Protected Branches

This will enforce protected branches on `master` and `develop`.

### Audit/Enforce on all projects

`sh setup-protected-branches.sh` -- Loops over all your `PROJECTS`

### Audit/Enforce on a single project

`sh setup-protected-branches.sh -p 1455` -- know your project id or be prepared for it to loop over all your `PROJECTS`.

## Push Rules

This will establish the `PUSH_RULES` which is a regex (ruby) for your Jira or Ticket system formatting in `vars.sh`.  This can detour "made fix" or other useless commit messages from making it into your repository.

### Audit/Enforce all projects

`sh setup-push-rules.sh` -- Loops over all your `PROJECTS`

### Audit/Enforce single project

`sh setup-push-rules.sh -p 1455` -- know your project id or be prepared for it to loop over all your `PROJECTS`.

## Environments

This will audit known projects (array in vars.sh) for matching/validating labs and warning about those that do not match.
It will create labs if they are missing.  This is mainly for dealing with manually created projects.

### Audit/Enforce all projects

`sh setup-environments.sh` - will loop thru PROJECTS array and report unexpected labs or create expected LABS off array.

### Audit/Enforce single project

`sh setup-environments.sh -p "1456"` - requires you know your Project Id

## Variables

### Audit/Enforce all projects services

`sh setup-variables.sh` - will loop thru PROJECTS array and use services in VARIABLES_FILE

### Audit/Enforce single project services

`sh setup-variables.sh -p "1456"` - requires you know your Project Id

## Approvals

### Audit/Enforce all projects approvals

`sh setup-approvals.sh` - will loop thru PROJECTS array and set approvals

### Audit/Enforce single project approvals

`sh setup-approvals.sh -p "1456"` - requires you know your Project Id

## Services

### Audit/Enforce all projects services

`sh setup-services.sh` - will loop thru PROJECTS array and use services in `VARIABLES`

### Audit/Enforce single project services

`sh setup-services.sh -p "1456"` - requires you know your Project Id

### Example ~/company/variables.json

Used to establish base CI Variables and Service Integrations.

```json
{
    "ALL": {
        "AWS_ACCESS_KEY_ID": "*",
        "AWS_SECRET_ACCESS_KEY": "*",
        "SONAR_HOST_URL": "https://sast.sre-security.apps.com",
        "SONAR_TOKEN": "GET YOURS"
    },
    "services": [
        {
            "name": "jira",
            "data": {
                "url": "https://team.atlassian.net",
                "username": "user@company.com",
                "password": "GET YOUR OWN API",
                "jira_issues_enabled": true,
                "jira_project_key": "ABCD",
                "issues_enabled": true,
                "project_key": "ABCD",
                "active": true,
                "jira_issue_transition_id": "GET YOURS",
                "merge_requests_events": true,
                "comment_on_event_enabled": true,
                "commit_events": true,
                "push_events": true,
                "issues_events": false,
                "pipeline_events": true,
                "wiki_page_events": false,
                "job_events": true
            }
        },
        {
            "name": "microsoft-teams",
            "data": {
                "webhook": "GET YOUR OWN",
                "active": true,
                "push_events": false,
                "issues_events": false,
                "confidential_issues_events": false,
                "merge_requests_events": true,
                "tag_push_events": true,
                "note_events": false,
                "confidential_note_events": false,
                "pipeline_events": true,
                "wiki_page_events": false,
                "job_events": true,
                "comment_on_event_enabled": true,
                "branches_to_be_notified": "all",
                "notify_only_broken_pipelines": true
            }
        },
        {
            "name": "confluence",
            "data": {
                "confluence_url": "Link to workspace"
            }
        }
    ]
}
```
