# AWS ECW Bastion Instance config.toml example

You can also start with [this](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/) page
to get going.  I've highlighted some of my initial steps below from my notes.
Also [this](https://about.gitlab.com/2017/11/23/autoscale-ci-runners/) page. 

Below is a stub from a gitlab-runner for AWS.
It uses the S3 as a cache, and will stand up EC2 instances for on demand
building/scanning.  After 30 minutes it will terminate the instance if it is not
used.  Peak hours are set so at night and weekends it terminates them quicker.

This assumes a gitlab user, and gitlab group with EC2FullAccess and S3FullAccess.
Please create a user 'gitlab-autoscaler' and a role 'gitlab' in IAM.

You will need a registry token if your setting this up with Gitlab.  You can
create a share runner or one specifically for a project/group.  More on that:
https://docs.gitlab.com/ee/ci/runners/

```toml
concurrent = 10
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "gitlab-aws-autoscaler"
  url = "https://yourdomain.com"
  token = "xxxxxxxxxxxxxxxxxxx"
  tls-ca-file = "/etc/gitlab-runner/certs/CORP_Root_CA.crt"
  executor = "docker+machine"
  limit = 20
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = true
    disable_cache = true
    # added /etc/docker/certs.d/yourdomain.com/CORP_RootCA.crt to host
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock", "/etc/docker/certs.d:/etc/docker/certs.d"]
    shm_size = 0
  [runners.cache]
    Type = "s3"
    ServerAddress = "s3.amazonaws.com"
    AccessKey = "AKIAJNQ7XXXXXXXXXX"
    SecretKey = "3zxpYvaMxveZbTRTPOXXXXXXXXXXXXXXX"
    BucketName = "CORP-gitlab-cache"
    BucketLocation = "us-west-2"
    Shared = true
     [runners.cache.s3]
     [runners.cache.gcs]

  [runners.machine]
    IdleCount = 0    # 0 recommended
    IdleTime = 1800  # 30 mintues
    MaxBuilds = 100
    OffPeakPeriods = [
      "* * 0-9,18-23 * * mon-fri *",
      "* * * * * sat,sun *"
    ]
    OffPeakIdleCount = 0
    OffPeakIdleTime = 1200
    MachineDriver = "amazonec2"
    MachineName = "gitlab-docker-machine-%s"
    MachineOptions = [
   # Setup ~/.aws/credentials on the server.  Using the below caused command line issues.
   #   "amazonec2-access-key=AKIAJNQ7XXXXXXXXXXXX",
   #   "amazonec2-secret-key= 3zxpYvaMxveZbTRTPOXXXXXXXXXXXXXXXX",
      "amazonec2-region=us-west-2",
      "amazonec2-vpc-id=vpc-abc123",
      "amazonec2-subnet-id=subnet-123456",
      "amazonec2-use-private-address=true",
      "amazonec2-tags=runner-manager-name,gitlab-aws-autoscaler,gitlab,true,gitlab-runner-autoscale,true",
      "amazonec2-security-group=docker-machine-scaler",
      "amazonec2-instance-type=m4.xlarge",
    ]
```

## Setup a EC2 t2.micro

Install docker and docker machine

### Install a [Gitlab Runner](https://docs.gitlab.com/runner/install/linux-repository.html)

Edit the /etc/gitlab-runner/config.toml
Note: You may need to add a local ~/.aws/credentials file to store the AWS
user access for EC2, and S3
 
### Create a S3 Bucket

Give it a name like `CORP-gitlab-[teamname]`

## CloudFormation Template

You could leap off of a template created here:
https://github.com/chialab/aws-autoscaling-gitlab-runner

## Documented issues (longer term)

On 7/15 a updae to docker:stable (19.03) caused a [TLS issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/64959).
Fix was documented to set a environment value in the config.toml on the runner.
`environment = ["DOCKER_TLS_CERTDIR="]`
