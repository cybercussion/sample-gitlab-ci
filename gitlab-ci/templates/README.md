# Use with your Code Editor

For VSCode see https://marketplace.visualstudio.com/items?itemName=cstuder.gitlab-ci-validator 

# templates

To use any of the templates you simply need to create a `.gitlab.yml` file
located in the root of your project.

```yml
#variables:
  # DAST Scan dev or prod url
#  website: "domain.com"
#  GIT_SUBMODULE_STRATEGY: recursive  # Use if you have git submodules in your repo

# Default Stages
stages:
  - test
  #- performance

# Templates for above stages
include:
  # Test Stage
  - https://yourdomain.com/gitlab-ci/templates/raw/master/.sast.yml                 # C sharp dotnet 2.1 +
  - https://yourdomain.com/gitlab-ci/templates/raw/master/.dependency_scanning.yml  # C sharp coming soon!
  - https://yourdomain.com/gitlab-ci/templates/raw/master/.code_quality.yml         # C sharp coming soon! (this will show nothing until it has something to compare to)
  - https://yourdomain.com/gitlab-ci/templates/raw/master/.license_check.yml
  #- https://yourdomain.com/gitlab-ci/templates/raw/master/.gittyleaks.yml           # will create HTML artifact Report (SAST now does some of this)
  #- https://yourdomain.com/gitlab-ci/templates/raw/master/.dast.yml                # use var website, needs endpoint/url
  # Performance Stage
  #- https://yourdomain.com/gitlab-ci/templates/raw/master/.performance.yml         # uses same website/endpoint - front end apps
```

## About Templates

Originally gitlab was setup to use a public repo for templates.  This changed
in Gitlab 11.7. https://docs.gitlab.com/ee/ci/yaml/#include 
You now have the ability to use local templates, as well as Gitlab supplied ones.
This was a major improvement over prior versions.

General overview if CI features https://docs.gitlab.com/ee/ci/examples/ 

## About Artifacts

Artifacts should be referenced local to the `$CI_PROJECT_DIR`.  If you attempt
to obtain these from other locations I have seen issues with permissions obtaining
assets from `/tmp/` or another location within the docker container.
To correct that type of result, I would copy from target to the `$CI_PROJECT_DIR`
that way when you want to store artifacts in gitlab you can do so in a `after_script`
block.

```yaml
...
artifacts:
    expire_in: 1 week
    paths: 
      - folder/*

```

## Tags (not to be confused with a git tag)
You can tag a runner which is more or less a label.  You'll note you can call
something `windocker` or `lindocker` and then specify a job to happen directly
on that specific runner.  This gives you greater control at a job level to
perform tasks at the shell (windows or linux), docker or any other runner and 
executor you've setup.

Currently, all test jobs are pointed at `aws-docker` tag which is a EC2 Autoscaler.
You can enable these "shared runners" on your project by navigating to:
Settings->CI / CD->Runners

## Variables
See: https://docs.gitlab.com/ee/ci/variables/ 
There are variables you can specify at a system level and those custom ones
you create.  These are role based and can also be flagged secret or private.
Please note how you use these in a `.gitlab-ci.yml` file also correlates to
the executor you are running the job on.  For example `%VAR%` would occur on
windows batch, and `$env:VAR` on Powershell, but `$VAR` would occur on linux
shell.
Environment Variables can be set at a Group or Project level as well as in the
CI file itself.  Manually setting these variables can be done on the pipeline
if you kick one off manually.  Protected Variables can only be read from protected
branches and only viewable to Maintainers and up.

# Runners

There is a `aws-docker` instance running which is a ec2 autoscaler.  It essentially
spins up the needed instances, processes your job/tasks then after 15 minutes will
spin down.  If its needed again, and not in use during this period, Gitlab will use
the idle instance to save time performing security scans and builds.
Each project in Gitlab has a Settings -> CI / CD section.  Here is where you'll
want to ensure you've enabled Shared Runners so your project can benefit from this
established Gitlab-Runner.

Alternatively, you can establish a gitlab-runner on Windows or Linux by specifying a executor.
See:  https://docs.gitlab.com/runner/executors/

Download: https://docs.gitlab.com/runner/install/ 

Registering: https://docs.gitlab.com/runner/register/

You can even run a gitlab-runner in docker:

```bash
docker run --rm -t -i -v /path/to/config:/etc/gitlab-runner --name gitlab-runner gitlab/gitlab-runner register \
  --non-interactive \
  --executor "docker" \
  --docker-image alpine:3 \
  --url "https://gitlab.com/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --description "docker-runner" \
  --tag-list "docker,aws" \
  --run-untagged \
  --locked="false"
```

You can install a runner on a specific project, or create a shared runner.
On a project:
Settings -> CICD -> Runners - note the registration token

A admin can create a Shared Runner under Admin -> Runners

```
# Get the Registration token if your manually creating a config.toml
curl -XPOST -k -H 'Content-Type: application/json' -H 'Accept: application/json' \                                                                                                                                     60 ↵ 
  -d '{"token":"abcdefghijklmnopqrs","run_untagged":true,"locked":false}' \
  https://yourdomain.com/api/v4/runners
```

## config.toml

A `config.toml` file will get created upon registering a gitlab runner with
a executor.  This is read by the gitlab-runner and as you change it, the
runner will re-read the settings.  You can register more runners using the
same gitlab-runner.  Remember if you use the shell executor, you may need to
restart the console/terminal to pick up any recent installations.
Using a docker executor enables you to pick the docker-in-docker executor which
offers you a quick way to specify the docker image, and any service you need.
This ensures a clean slate each time its used.

Sample:

```toml
concurrent = 4
check_interval = 10
log_level = "warning"

[[runners]]
  name = "NAMEOFINSTANCE"
  url = "URLTOREPO"
  token = "TOKEN (NOT THE REGISTRATION TOKEN)"
  tls-ca-file = "/etc/gitlab-runner/certs/CORP_Root_CA.crt"
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "alpine"
    privileged = true
    # optionally pass in /etc/docker/certs.d/yourdomain.com/CORP_Root_CA.crt (if you make it)
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock", 'etc/docker/certs.d/:/etc/docker/certs.d']
    disable_cache = false
    shm_size = 0
  [runners.cache]
    Insecure = false
```

Because CORP has a poorly encrypted / self-signed certificate there are some
added hurdles to get past.  Communication from a gitlab-runner back to the Gitlab
Repository may b a problem.  Due to this, you'll notice the `CORP_Root_CA.crt`
had been copied and placed in `/etc/gitlab-runner/certs/`.

If you are using docker-in-docker (dind) even further you need to deal with this
cert AGAIN because it won't be present in downstream docker images you are using
unless you specifically pull it from Artifactory like you see happening in several
of these templates.

Even interaction with the Gitlab Registry for pushing a built docker image back to
Gitlab resulted in me needing to place the certificate in /etc/docker/certs.d on the
host system, and I passed it thru to the downstream docker executors (dind) as well
as adding a `--insecure-repository` argument in the YAML file to get that to work.

To propery communicate with the CORP Gitlab instance you'll need to also
get the cert from the domain and specify the `tls-ca-file` in the runner.

# Customizing your own `.gitlab-ci.yml`

* See:  https://docs.gitlab.com/ee/ci/variables/#gitlab-ci-yml-defined-variables
* See:  https://docs.gitlab.com/ee/ci/README.html 

There are other examples on line of more advanced setups.  There are some tips on
keeping your YAML DRY (Don't Repeat Yourself).  

* https://dev.to/michalbryxi/how-to-dry-your-gitlab-ciyml-16pc
* https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab/ci/frontend.gitlab-ci.yml
* https://gitlab.com/gitlab-org/release-tools/blob/master/.gitlab-ci.yml

## Other notes

Certain jobs like you see have artifacts that gitlab can use.  You'll see these
integrate like with SAST, License Management, Code Quality and jUnit.  These
become more apparent when making a Merge Request which will cover new tiles/tabs
like Security, Licenses, Tests etc...


# About Executors (Crawl, Walk, Run)

Gitlab allows for shell, docker, docker+machine, kubernetes among others.
One important note about using 'docker in docker' or dind based approaches.  The
docker in docker executor commonly kicks off containers running in containers.
this means you need to manage concurrency.  dind is great because you get
separation in containers, however you lose the ability to cache docker images
unless you are using a external registry to halt re-downloading these.

Local tests using Fedora Atomic with access to the `/var/run/docker.sock` do
not seem to allow it to also see the `/var/lib/docker` where all the containers
and images are stored on the host OS.  This is all currently being researched.
The net result is it re-downloads the images which is undesirable. This is a 
time suck when it comes to building/rebuilding.
Kubernetes would be a cleaner use for longer term concurrent support, caching
and functionality.

# Deploying

You can make some distinct decisions about when to deploy and how you want to deploy.
This typically requires you have access to the location either on prem or in the cloud.
Gitlab allows you to protect variables on protected branches like master or develop.
Owners and Maintainers can then adjust Group or Project Variables to include these so
they are not hardcoded in-the-clear in the `.gitlab-ci.yml` file.
You can choose to use the `when: manual` option to require a manual "play button".
This would then mean (for example) a deploy to production requires you push play.

```yml
deploy_staging:
  stage: deploy
  script:
    - echo "Deploying to staging server"
    #- command to make that happen ...
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - /^release\/[0-9]{4,5}$/  # release/12345 ( this won't respond to RC1)
    # Alternatively listen to a tag structure
    #- tags
    #- /^v[0-9](?:\.[0-9]){2,3}/  # v1.2.3
    
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
    #- commands to make that happen ...
  environment:
    name: production
    url: https://example.com
  when: manual  # this will activate a play button
  only:
  - master      # this can happen on a branch
                # you could even do only or except tags.
```

Other links on this subject:

* https://about.gitlab.com/2017/07/13/making-ci-easier-with-gitlab/ 

## Access Concerns (More Separation of Powers workarounds)

If there is a separation of power issue, good news.  Create a project elsewhere
the Dev Team doesn't have access too and run a 'trigger_pipeline' job that passes
these concerns off to the project you'll deploy via a API call or ChatOps.

* https://docs.gitlab.com/ee/ci/triggers/
* https://docs.gitlab.com/ee/ci/chatops/

## Single Project vs Cross-Project Considerations

As your project count grows either due to necessity or the passage of time; you
may need to consider how to orchestrate this.  Obviously this comes down to how
this is envisioned to be done and who ultimately does it.  Once all that is identified,
the team can sort out if this is something possible, or something that can be exposed.
For example - The current [Release Dashboard](http://10.2.30.93/releaselist) could be
expanded to support Okta.  Once a AD group is defined that can release to prod, the
button push(es) can be triggered from there with the proper privilege.  Since this currently
has a manifest of all projects in-flight, and some eye on the status of builds its poised
to also be able to do more without bouncing thru multiple systems to search for status.
