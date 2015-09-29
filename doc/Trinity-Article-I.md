# Docker, Elastic Beanstalk and Git: a useful trinity for agile development?

By Duncan Rutland, Sr. Solution Architect, Rackspace 2015

---

## I - Prologue 

You have been assigned the task of writing an enhancement to _the project_, which you undertake within a feature branch on your laptop (merging frequently from master of course). Reaching a stable point, you do decide to do a final merge, commit and check out how it runs in a local container runtime environment. You type "git commit -m ..." and a hook automatically triggers a new immutable Docker container to be built, local unit tests to be run, and upon success the new container is pushed to your [Dockerhub](https://hub.docker.com/) repository and spun up in the Docker host running on your laptop. A quick visual smoke test reveals nothing of concern. You decide to deploy the new feature branch to a fresh staging environment for further tests to be run. A quick "eb deploy" command triggers a new staging environment to be build and the new container image (identical to the one running on your laptop) to be spun up. Happy that the new application version is working in an environment close to production, you push your feature branch to Github where automated regression tests are triggered. Finally, you submit a pull request to have your successfully tested feature branch merged into master and an automated CI/CD workflow (triggered by the commit of merged branch) takes care of the rest.

## II - Introduction

This is the first of a multi-part series that demonstrates one solution by which a developer can make the transition of code from laptop to production as pain-free as possible. The fictional semi-automated deployment scenario above is just one solution from a swarming myriad of possible workflows (with varying degrees of automation) that can reduce operational overhead on the developer. This series will make use of technologies such as Git, Docker, Elastic Beanstalk, CircleCI and other standard tools. 

In this first article, we will tackle some fundamental building blocks that will allow for more exotic combinations in subsequent articles:

1. Environment setup
2. Elastic Beanstalk configuration
3. Manual environment deployment
4. Deploying a feature release to local container
5. Transitioning releases to dev and staging environments

**Caveat**: The current version of this project (as of 9/27/15) imposes a deliberately simplified example application, release workflow (i.e. no automated tests) and environment layout (just local dev, staging and production) in order to illustrate the key concepts behind running Git, Docker, and Elastic Beanstalk as an integrated unit. Later articles in this series will tackle some more realistic use cases including incorporation in to CICD workflows and more complex applications than run on multiple containers and consume other AWS services.

**Disclaimer**: The demonstration code in the corresponding [repository] (https://github.com/behemothaur/trinity) is for illustrative purposes only, and may not be sufficiently robust for production use. Users should carefully inspect sample code before running in a production environment. Use at your own risk.

**Disclosure**: The idea of a Makefile mechanism to automate container preparation, build, push etc. was inspired by [this](http://victorlin.me/posts/2014/11/26/running-docker-with-aws-elastic-beanstalk) excellent article by Victor Lin.

## III - Design Principles

The following fundamental design principles will be followed during the course of this adventure:

1. **Simplicity** - adhere to the principles of [KISS] (https://en.wikipedia.org/wiki/KISS_principle) and [Occam's Razor] (https://en.wikipedia.org/wiki/Occam's_razor)
2. **Agility** - switching between environments and deploying application releases should at most a single _simple_ shell command
3. **Immutability** -  application container images will be considered as immutable. This will eliminate runtime dependency issues when deploying applications across environments. The local development runtime environment should thus be very close to production. 
4. **Automation** - Nirvana will be fully automated deployment of application releases triggered by Git workflow events

NOTE: Strictly speaking the kernel and container supporting services _could_ differ between hosts however the impact on most applications would be minimal given that most dependencies exist within the runtime environment.

## IV Prerequisites

This series of articles and corresponding demonstration code has some dependencies on local environment and accounts with Docker, Github and AWS. You will need the following:

1. Ruby and Python interpreters
2. Unix "Make" utility
3. Elastic Beanstalk CLI tools (eb-cli)
4. Local Git binaries
5. AWS Account with default Public/Private/NAT VPC configured
6. AWS IAM user with appropriate policy set
5. Github account
6. DockerHub account
6. Local Docker host (e.g. via Docker Toolbox for OS X)

## V - Demonstration

NOTE: Rather than start with the details on how to set this up in your own environment, I decided to move that stuff to Appendices that follow and dive straight into the demonstration. In order to replicate the demonstration, the reader will need to have successfully installed & configured the dependencies as per Appendix A, and setup a local environment as per Appendix B.

### Setting the scene

Your latest application version is running in production, as a quick check with "eb status" confirms:

~~~bash
~/trinity/master> eb status

Environment details for: trinity-prod
  Application name: trinity
  Region: us-west-2
  Deployed Version: v1_1-1-g5bf2
  Environment ID: e-pi9ycc8gfs
  Platform: 64bit Amazon Linux 2015.03 v2.0.2 running Docker 1.7.1
  Tier: WebServer-Standard
  CNAME: trinity-prod-vw9hejjzuh.elasticbeanstalk.com
  Updated: 2015-09-28 01:14:36.798000+00:00
  Status: Ready
  Health: Green
  
~/trinity/master>
~~~  

You decide to take a look in your browser, using the "eb open" command:

~~~bash
~/trinity/master> eb open
~~~

![Prod](https://s3-us-west-2.amazonaws.com/dirigible-images/trinity-prod.png)

### New "feature" request
---

It seems that some extra-terrestrial users (close acquaintances of HAL, I am led to believe) took offense at the rather limited scope of the greeting and made complaints to customer service team. A Github issue (#1 no less) was raised to this effect and you were assigned.

### Start work in feature branch
---

Eager to put this issue to bed, you create a feature branch and start work immediately:

~~~bash
~/trinity/master> git checkout -b issue-001 master
Switched to a new branch 'issue-001'
~~~ 

You make the necessary changes to app.rb and commit:

~~~bash
~/trinity/issue-001> git commit -a -m "Fixed #1 - Greeting message scope offensive to extra-terrestrials"
[issue-001 76f9252] Fixed #1 - Greeting message scope offensive to extra-terrestrials
 1 file changed, 1 insertion(+), 1 deletion(-)
~~~

### Create new application container
---

Since this is a Dockerized application, you can create a new container image and test this image locally before pushing to remote staging environment. A simple "make" is all that is required to build the container and push to Docker hub:

~~~bash
~/trinity/issue-001> make
./Docker/build_dockerrun.sh > Dockerrun.aws.json
git archive -o Docker/trinity.tar HEAD
docker build -t djrut/trinity:`git describe --tags` --rm Docker
Sending build context to Docker daemon 3.608 MB
Step 0 : FROM ruby:slim
 ---> c80da6b5b71b
Step 1 : MAINTAINER Duncan Rutland <duncan.rutland@gmail.com>
 ---> Using cache
 ---> 0d47bd3b0475
Step 2 : RUN mkdir -p /usr/src/app
 ---> Using cache
 ---> 04d15bc0ba0e
 
[...SNIP...]

~/trinity/issue-001> 
~~~



### Test new application container locally
---

Now that we have a new Docker image containing the recent commit, let's first perform a quick test on our local Docker host using the eb-cli tool "eb local run" command to spin-up the new container:

~~~bash
~/trinity/issue-001> eb local run
v1.1-2-g76f9252: Pulling from djrut/trinity
843e2bded498: Already exists
[...SNIP...]
8ea23fed0e62: Already exists
Digest: sha256:7429729815fde70daebc9771b5fefabcf30d7a237f567e6f8f983e087935bb72
Status: Image is up to date for djrut/trinity:v1.1-2-g76f9252
Sending build context to Docker daemon 3.598 MB
Step 0 : FROM djrut/trinity:v1.1-2-g76f9252
 ---> 8ea23fed0e62
Step 1 : EXPOSE 80
 ---> Running in aae0380604b1
 ---> 36c175746264
Removing intermediate container aae0380604b1
Successfully built 36c175746264
[2015-09-28 02:50:05] INFO  WEBrick 1.3.1
[2015-09-28 02:50:05] INFO  ruby 2.2.3 (2015-08-18) [x86_64-linux]
== Sinatra (v1.4.6) has taken the stage on 80 for development with backup from WEBrick
[2015-09-28 02:50:05] INFO  WEBrick::HTTPServer#start: pid=1 port=80
...
~~~

You open a browser window and connect to the Docker host IP and port that is running the new application version (in this case, http://192.168.99.100/):

![Local](https://s3-us-west-2.amazonaws.com/dirigible-images/trinity-local.png)

Success! The new greeting message is working as expected. The next step is to run the new container images in the staging environment to see how this would work in production.

### Test new application container in staging environment
---

A simple "eb create" command is all that is needed to bind this branch (using the --branch_default option) and spin-up this new version into a fresh staging environment in your accounts default VPC:

~~~bash
~/trinity/issue-001> eb create trinity-stage-01 --branch_default
~~~

This time the "eb open" command can be run to fire up a browser window pointing to the staging environment:

~~~bash
~/trinity/issue-001> eb open
~~~

...and voila! The new application image is running successfully in staging.

![Staging](https://s3-us-west-2.amazonaws.com/dirigible-images/trinity-stage.png)

NOTE: For longer running branches (such as those that wrap entire versions/milestones), this staging environment is persistent and only requires an "eb deploy" to push newer versions, after committing changes and running "make". 
 
## Conclusion

During this demonstration, we examined a simplified use-case that enabled a simple and agile deployment mechanism with immutable application containers. The developer was able to use three simple shell commands "commit", "make" and "eb deploy" to build a new immutable container & push to the appropriate environment. This approach dramatically reduced the likelihood of broken dependencies as application releases are progressed from developer laptop onto to staging and production.

In **Part II** of this series we will take a peek under the covers to examine how we integrated Docker, Elastic Beanstalk and Git to enable the simple example above.

In **Part III**, we will make this look closer to a real production scenario by adding some additional components (and external dependencies) to the application and introduce unit tests.

In **Part IV**, we will show how this application can integrate into a fully automated CI/CD workflow using CircleCI.

Thank-you for your time and attention!


---
 
## Appendix A - Dependencies

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

## Appendix B - Environment Setup

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
