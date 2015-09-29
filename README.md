# Project: TRINITY
---
## Introduction

This demonstration project shows _one_ solution by which a developer can make the transition of code from laptop to production as pain-free as possible. This is just one solution from a swarming myriad of possible workflows (with varying degrees of automation) that can reduce operational overhead on the developer. This code will make use of technologies such as Git, Docker, Elastic Beanstalk, CircleCI and other standard tools. 

**Caveat**: The current version of this project (as of 9/27/15) imposes a deliberately simplified example application, release workflow (i.e. no automated tests) and environment layout (just local dev, staging and production) in order to illustrate the key concepts behind running Git, Docker, and Elastic Beanstalk as an integrated unit. Later articles in this series will tackle some more realistic use cases including incorporation in to CICD workflows and more complex applications than run on multiple containers and consume other AWS services.

**Disclaimer**: The demonstration code in this repository is for illustrative purposes only, and may not be sufficiently robust for production use. Users should carefully inspect sample code before running in a production environment. Use at your own risk.

**Disclosure**: The idea of a Makefile mechanism to automate container preparation, build, push etc. was inspired by [this](http://victorlin.me/posts/2014/11/26/running-docker-with-aws-elastic-beanstalk) excellent article by Victor Lin.

## Prerequisites

This demonstration code has some dependencies on local environment and accounts with Docker, Github and AWS. You will need the following:

1. Ruby and Python interpreters
2. Unix "Make" utility
3. Elastic Beanstalk CLI tools (eb-cli)
4. Local Git binaries
5. AWS Account with default Public/Private/NAT VPC configured
6. AWS IAM user with appropriate policy set
5. Github account
6. DockerHub account
6. Local Docker host (e.g. via Docker Toolbox for OS X)

## Dependencies

The following section outlines the steps needed to setup a local environment on Max OS X.
 
### Install Homebrew
~~~bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
~~~
### Install Python
~~~bash
sudo brew install python
~~~
### Install eb-cli
~~~bash
sudo pip install eb-cli
~~~

### Install Docker Toolbox
Follow the instructions [here] (https://docs.docker.com/installation/mac/) to install and configure Docker host running in a VirtualBox VM on OS X.

NOTE: _I had issues with connectivity to the host starting after initial install (I was getting "no route to host"). After some troubleshooting, this was remedied by a restart of OS X. It is not necessary, as some older issues relating to this problem indicate, to create manual NAT table entries_

### Setup Git

Most modern Unix variants will have the git package already installed. Follow the instructions [here] (https://help.github.com/articles/set-up-git/) to setup Git. There are some useful instructions [here] (https://help.github.com/articles/caching-your-github-password-in-git/) to setup credential caching to avoid having to frequently re-type your credentials. 

### Configure AWS credentials

My preferred approach is to populate the .aws/credentials file as follows:

~~~bash
[default]
aws_access_key_id = [ACCESS KEY]
aws_secret_access_key =  [SECRET]
~~~

You will need an IAM role assigned to this user or containing group that has adequate permissions to IAM, EB, EC2, S3 etc... Since this is my playground account I used a wide open admin policy:

~~~
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
~~~

Caveat: This IAM policy is **not** recommended for production use, which should utilize a fine-grained IAM policy.

## Environment Setup

There are number steps involved here to get the environment setup, but remember that these are _one time_ actions that you will not need to repeat again unless you need to recreate the environment again from scratch.
 
### Step 1 - Choose a name for your application
It will be necessary to create a unique name for your forked version of the trinity application. This is required since Elastic Beanstalk DNS CNAME records must be globally unique. We shall refer to this name as *APP_NAME* henceforth. 

### Step 2 - Fork & clone Git repository
The first step is to fork and clone the demo Git repository. Full details on how do to this can be found [here](https://help.github.com/articles/fork-a-repo/) however the basic steps are:

1. On GitHub, navigate to the [behemothaur/trinity](https://github.com/behemothaur/trinity) repository 
2. In the top-right corner of the page, click **Fork**. You now have a fork of the demo repository in your Github account.
3. Create local clone, substituting your Github USERNAME

~~~bash
git clone https://github.com/[USER_NAME]/trinity.git
~~~
 4. Create upstream repository to allow sync with original project
 
~~~bash
git remote add upstream https://github.com/behemothaur/trinity.git
~~~

### Step 2 - Docker Hub setup 


1. Create a Docker Hub account and create a repository for *APP_NAME*
2. Edit "Makefile"
2. Substitute USER value (currently set to "djrut") with your Docker Hub username.
3. Substitute REPO value (currently set to "trinity") with your newly created *APP_NAME*
4. Login to Docker hub (this will permanently store your Docker Hub credentials in ~/.docker/config.json)

~~~ bash
docker login
~~~

### Step 3 - Initialize Elastic Beanstalk environments 

NOTE: This step requires that you either have a default VPC configured with public/private NAT configuration _or_ you explicitly specify the VPC and subnet IDs during Elastic Beanstalk environment configuration step. I will be using the latter mechanism to supply a previously saved configuration to the "eb create" command.

#### a) Initialize the Elastic Beanstalk Application

~~~bash
eb init [APP_NAME] --region us-west-2 --platform "Docker 1.7.1"
~~~

Upon success you should a message like "Application [APP_NAME] has been created."

#### b) Create "production" Elastic Beanstalk environment

Ensure that you are currently in the up-to-date "master" branch of the application:

~~~bash
prompt> git status
On branch master
Your branch is up-to-date with 'origin/master'.
nothing to commit, working directory clean 
~~~

Run the "eb create" substituting *APP_NAME* for your application name:

~~~bash
eb create [APP_NAME]-prod --branch_default
~~~

You should now see a trail of events as Elastic Beanstalk launches the environment. Here is a snippet from mine:

~~~bash
Creating application version archive "v1_1".
Uploading trinity/v1_1.zip to S3. This may take a while.
Upload Complete.
Environment details for: trinity-prod
  Application name: trinity
  Region: us-west-2
  Deployed Version: v1_1
  Environment ID: e-pi9ycc8gfs
  Platform: 64bit Amazon Linux 2015.03 v2.0.2 running Docker 1.7.1
  Tier: WebServer-Standard
  CNAME: UNKNOWN
  Updated: 2015-09-27 19:24:42.760000+00:00
Printing Status:
INFO: createEnvironment is starting.
INFO: Using elasticbeanstalk-us-west-2-852112010953 as Amazon S3 storage bucket for environment data.
INFO: Created security group named: sg-d47aebb0
INFO: Created load balancer named: awseb-e-p-AWSEBLoa-XUW9PIDWF5JH
INFO: Created security group named: sg-d27aebb6
INFO: Created Auto Scaling launch configuration named: awseb-e-pi9ycc8gfs-stack-AWSEBAutoScalingLaunchConfiguration-1SUHKGKXB0C01
INFO: Environment health has transitioned to Pending. There are no instances.
INFO: Added instance [i-7b176ca0] to your environment.
INFO: Waiting for EC2 instances to launch. This may take a few minutes.
~~~

At this stage you can safely CTRL-C and wait a few minutes for the environment to be spun up. This takes longer for the first deployment since the full Docker image needs to be downloaded. Subsequent deployments of newer versions of the application will be faster since only the modified layers of the image need to be downloaded.

You can check periodically with "eb status" and wait for "Health: Green" to indicate that all is well:

~~~bash
prompt> eb status
Environment details for: trinity-prod
  Application name: trinity
  Region: us-west-2
  Deployed Version: v1_1
  Environment ID: e-pi9ycc8gfs
  Platform: 64bit Amazon Linux 2015.03 v2.0.2 running Docker 1.7.1
  Tier: WebServer-Standard
  CNAME: trinity-prod-vw9hejjzuh.elasticbeanstalk.com
  Updated: 2015-09-27 19:32:43.591000+00:00
  Status: Ready
  Health: Green
~~~ 

Finally, there is a handy command "eb open" that will open the current environment in your browser for a quick eye test:

~~~bash
eb open
~~~
