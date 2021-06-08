# Student: Louis Manabat (ID: s3719633)

## Contents Page:
- [Analysis and Solution](#Analysis-and-Solution)
    - [Analysis of the problem](#Analysis-of-the-problem)
    - [Explain and justify the solution](#Explain-and-justify-the-solution)
- [How to deploy the solutiion](#How-to-deploy-the-solutiion)
    - [Pre-requisites](#Pre-requisites)
        - [Manual installations](#Manual-installation)
        - [Semi-automatic installation](#Semi-automatic-installation)
        - [Setting up AWS Credentials](#Setting-up-AWS-Credentials)
        - [Pre-setup](#Pre-setup)
        - [KOPS Cluster Setup](#KOPS-Cluster-Setup)
    - [Running Commands](#Running-Commands)
        - [Distinction task (Production Approval)](#Distinction-task-(Production-Approval))
    - [Distinction Task](#Distinction-Task)
    - [Accessing Solution](#Accessing-Solution)
    - [Accessing Solution (Distinction task)](#Accessing-Solution-(Distinction-task))
- [How to tear down the solution](#How-to-tear-down-the-solution)


# Analysis and Solution
## Analysis of the problem
The process of creating the artifact has now been containerised into a Docker container. This simplifies part of the deployment of the solution. The next task is to get the solution running through Kubernetes on a CD pipeline to make the deployment of the solution easier.

## Explain and justify the solution
The solution uses several tools to deploy the solution. The process will essentially be automated, but to get it running, several Makefile commands need to be run to fully deploy the solution.

Tools:
GitHub: This is where the repository for the solution and the automation code will be stored on. In a further implementation of automating the process, CircleCI will be linked to GitHub to do CI/CD (Continuous Integration & Continuous Deployment)

Terraform: Terraform is the tool that automates the creation and updating of AWS services to help ease the process, and removes the need of having to create the services using manual labour. With this, it will lower the chances of using too many resources, meaning the company will save money, which then also means the company will gain a higher profit, which increases the satisfaction of the client. 

AWS: This is the service where the client wants to deploy the solution onto. Services such as an EC2 virtual machine instance, VPCs, S3 buckets and DynamoDB will be used to help run the Todo App solution when it is deployed.

CircleCI: CircleCI was used to automate the packing of the artifact, from doing linting and vulnerability checks to making a packed solution. It will also be used to fully automate the deployment process.

Docker: Docker will be used to containerise the application. It will pack the solution into an image. Once the the image has been created, it just needs to be deployed for it to be running.

Kubernetes: Kubernetes is a service that deploys, scales and manages the application. It will be using the container that Docker creates to deploy the application. 

Helm: Helm will be used to manage the Kubernetes cluster. This will manage things like the porting, databsing and the deploying of the application.

# How to deploy the solutiion

Please note before getting started you must have an AWS account to get started. The way this tutorial will do it will differ from how you may do it, so please keep that in mind. We will be running this in VirtualBox using an Ubuntu 20.04 image.

## Pre-requisites


## Manual installation
##### Please note that each line is a new command
### Updating system 
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install curl make wget vim -y
    sudo snap install kubectl --classic

### Installing AWS
    cd /tmp/
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install

### Installing Helm
    cd /tmp/
	wget https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz
	tar -zxvf helm-v3.6.0-linux-amd64.tar.gz
	sudo mv linux-amd64/helm /usr/local/bin/helm

### Installing KOPS
    cd /tmp/
	curl -LO https://github.com/kubernetes/kops/releases/download/v1.18.0/kops-linux-amd64
	chmod +x kops-linux-amd64
	sudo mv kops-linux-amd64 /usr/local/bin/kops

#### Installing Terraform
    cd /tmp/
    wget https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip
    unzip terraform_0.15.4_linux_amd64.zip
    sudo mv terraform user/local/bin

## Semi-automatic installation
##### Please note that each line is a new command
### Please run this command before starting the rest of the process
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install make -y

#### After successfully running that command, run the following commands (Each line is a new command)
    make install-deps
    make install-aws
    make install-helm
    make install-kops
    make install-tf


## Setting up AWS Credentials
##### Please note we will being using AWS Educate for this example

First login into AWS Educate and press the **My Classrooms** tab at the top. Find the course you are currently in and press the blue **Go to classroom** button on the right. Press **Continue** on the prompt that appears
<img src="readme-images/aws-edu-myclass.png" alt="AWS-Edu-MyClass" width=50% height=50%>

Upon entering the next page, press the **Account Details** button and you will be greeted with a bunch of credentials. Copy the entire set of text in the gray box as we will be using this for later. 
### Please note that these credentials should only be used by you and you only! Do not share this with anyone else
<br>
<img src="readme-images/aws-account-status.png" alt="AWS-acc-status" width=50% height=50%>
<img src="readme-images/aws-credentials.png" alt="AWS-creds" width=50% height=50%>
<br>

After doing this, open up a new tab in your terminal and run the command `mkdir ~/.aws` then run `vim ~/.aws/credentials` then press **INS** to activate insert mode then **Shift + INS** to paste the credentials. Follow this up with pressing **CTRL + C** then type in `:wq` to save and exit vim.
<br>
<img src="readme-images/aws-credentials-vim.png" alt="AWS-cred-vim" width=50% height=50%>
<img src="readme-images/aws-credentials-vim-2.png" alt="AWS-cred-vim-2" width=50% height=50%>

##### Please note that the credentials expire every 3 hours, so you will need to update them once they do expire.

## Pre-setup

### Bootstrap
The following command will create some files to make a remote backend. Run the command **once only** and them copy the two values into the respective variables in *main.tf* in the infra directory.

    make bootstrap
You should first see these variables after completing `make bootstrap`.
<br>
<img src="readme-images/bootstrap-vars-1.png" alt="boostrap-vars" width=30% height=30%>
<br>

Following that, you will copy the **dynamoDb_lock_table_name** and the **tf_state_bucket** and paste them into the *makefile*. You should be only changing the **bucket** (using the **tf_state_bucket** variable) and **dynamodb_table** (using the **dynamoDb_lock_table_name**) variables under the init command.
<br>
<img src="readme-images/bootstrap-vars-2.png" alt="boostrap-vars" width=50% height=50%>
<br>

After that, use the **kops_state_bucket_name** and add that to *config.yml*. Around line 34 (under the setup-cd command), there is a line that has;

    kops export kubecfg rmit.k8s.local --state s3://rmit-kops-state-
This also applies on around line 109 also on *config.yml*. It will be under the e2e job.
Replace the **rmit-kops-state-** with the variable that **kops_state_bucket_name** provided from the `make bootstrap` command.
<br>
<img src="readme-images/bootstrap-vars-3.png" alt="boostrap-vars" width=50% height=50%>
<br>
<img src="readme-images/bootstrap-vars-4.png" alt="boostrap-vars" width=50% height=50%>
<br>

Finally, use the **repository-url** output and add that to the **ECR** and **reponame** variables in *config.yml* (Somewhere around line 130 under the package jobs). The link before the forward slash ('/'), that goes into the **ECR** variable, whereas the name after the forward slash ('/'), goes into the **reponame** variable.
<br>
<img src="readme-images/bootstrap-vars-5.png" alt="boostrap-vars" width=50% height=50%>
<br>

Once you have compeleted that, push your changes to GitHub.

### Setting up CircleCI
We will now set up CircleCI to being deployment. Open up the link https://circleci.com/ and press the **Go to App** icon on the top right. If you haven't linked your GitHub account to CircleCI, please do it now. After that, go to the Projects page (button on the left side), and find the repository. Press the **Set up Project** button and it'll coninue to the next screen. Press the **Use Existing Config** button, then **Start Building**.
<br>
<img src="readme-images/circleci-setup-1.png" alt="circleci-setup" width=50% height=50%>
<br>
<img src="readme-images/circleci-setup-2.png" alt="circleci-setup" width=50% height=50%>
<br>
<img src="readme-images/circleci-setup-3.png" alt="circleci-setup" width=30% height=30%>
<br>

The first and inital pipeline should fail at the package job because it might be missing (or is using invalid) variables because it is running from the master branch.
<br>
<img src="readme-images/circleci-fail-master.png" alt="circleci-fail-master" width=50% height=50%>
<br>

The build should be successful as it only runs the build and integration-test jobs (if the pipeline runs from any other branch other than the master branch). If it does fail, ensure you have inputted the correct variables in the *config.yml* file and push the changes so it runs the pipeline again.
<br>
<img src="readme-images/circleci-pass-branch.png" alt="circleci-pass-branch" width=50% height=50%>
<br>

Next you will need to set up the AWS credentials. Get the variables from the [Setting up AWS Credentials](#Setting-up-AWS-Credentials) as we will be using them here as well.
<br>

First press the **Project Settings** button, then on the lefthand sidebar, press the **Environmental Variables** button.
<br>
<img src="readme-images/circleci-setup-4.png" alt="circleci-setup" width=50% height=50%>
<br>
<img src="readme-images/circleci-setup-5.png" alt="circleci-setup" width=20% height=20%>
<br>

From there you will need to pass the name of environmental variables (in all caps), and the variable itself. You do this by pressing the the **Add Environmental Variable** button. There should be three separate variables in there and should look like this.
<br>
<img src="readme-images/circleci-setup-6.png" alt="circleci-setup" width=50% height=50%>
<br>

##### Please note that the credentials expire every 3 hours, so you will need to update them once they do expire.

### Generate SSH Key
Running the following command will create an SSH key that will be used by Kubernetes.

    make ssh-gen

### KOPS Cluster Setup

Now we will spin up the KOPS cluster.

First run the following command to create the cluster

    make kube-create-cluster
You will get an error saying "*SSH public key must be specified when running with AWS*". Just ignore that as we move onto the next command.

<br>

Running the next command will use the SSH key previously created, to link it to AWS.

    make kube-secret
No errors means the make command was successfully run.

<br>

After that, run the following command to deploy the cluster to AWS

    make kube-deploy-cluster

<br>

Finally, export some config from the S3 kops bucket to finish off the spinning of the cluster using following command.

    make kube-config

<br>

The cluster should take up to 10 minutes for it to ready itself for deployment. So running the following command too early might result in an error.

    make kube-validate
<img src="readme-images/kube-validate-fail.png" alt="kube-validate-fail" width=40% height=40%>
<br>

A successful validation of the cluster should look like this
<br>
<img src="readme-images/kube-validate-pass.png" alt="kube-validate-pass" width=40% height=40%>
<br>

Finally, run this command to create the namespace for the application to run on.

    make namespace-up
<img src="readme-images/namespace-up.png" alt="namespace-up" width=40% height=40%>
<br>

## Running Commands

### Setup test environment
Next you want to being setup the infrastructure that's going to host the solution. Open up the console to this link https://console.aws.amazon.com/vpc/home?region=us-east-1#. Follow this up with opening up the **Subnets** tab.
<br>
<img src="readme-images/tfvars-setup-1.png" alt="tfvars-setup" width=30% height=30%>
<br>

You want to copy the two Subnet IDs (under the name us-east-1a.rmit.k8s.local and us-east-1b.rmit.k8s.local), then copy it into the terraform.tfvars file in the infra directory.
<br>
<img src="readme-images/tfvars-setup-2.png" alt="tfvars-setup" width=30% height=30%>
<br>
<img src="readme-images/tfvars-setup-3.png" alt="tfvars-setup" width=20% height=20%>
<br>

You want to then return to the [VPC](https://console.aws.amazon.com/vpc/home?region=us-east-1#) page, then open up the **VPCs** tab (above the **Subnets** tab). You want to copy the VPC ID under the name *rmit.k8s.local*
<br>
<img src="readme-images/tfvars-setup-4.png" alt="tfvars-setup" width=30% height=30%>
<br>
<img src="readme-images/tfvars-setup-5.png" alt="tfvars-setup" width=20% height=20%>
<br>

After this you will want to push the changes to your repository. ***Please note that for this to deploy, it will need to done in the master branch. If you have branched off elsewhere, do a pull request into master***.

### Distinction task (Production Approval)
With the production environment also being deployed, you will need to approve that after the e2e job is complete. Open up the pipeline in CircleCI, and in the latest pipeline, it should have a status saying **On Hold**. To let this pass, you need to press the thumb icon in the actions column (refer to image below) to progress into the deploy-prod job.
<br>
<img src="readme-images/ci-approval1.png" alt="ci-approval" width=60% height=60%>
<br>

A prompt will show that you want to confirm the approval to be approved. Press the **Approve** button to move to the deploy-prod job. Once done, a tick should appear where the thumb icon initially was, then the pipeline will be complete.
<br>
<img src="readme-images/ci-approval2.png" alt="ci-approval" width=40% height=40%>
<br>
<img src="readme-images/ci-approval3.png" alt="ci-approval" width=60% height=60%>
<br>

Your CircleCI should show 4 different jobs: *build*, *integration-test*, *package* and *deploy-test*. The pipeline should look like this if it's successful.
<br>
<img src="readme-images/successful_master_ci_build1.png" alt="successful_master_ci_build" width=70% height=70%>
<br>
<img src="readme-images/successful_master_ci_build2.png" alt="successful_master_ci_build" width=60% height=60%>
<br>

#### Distinction Task
With the production deployment also added to the pipeline, it should now look like this.
<br>
<img src="readme-images/di-deploy-prod2.png" alt="deploy-prod" width=70% height=70%>
<br>
<img src="readme-images/di-deploy-prod1.png" alt="deploy-prod" width=60% height=60%>
<br>

## Accessing Solution
### Via CircleCI
To get the URL to access the solution via CircleCI, open up the *Smoke Test* step in the *deploy-test* job, and you should see a url that was echo'ed at the bottom.
<br>
<img src="readme-images/load-balancer_smoke-test.png" alt="lb_smoke-test" width=60% height=60%>
<br>

### Via terminal (kubectl)
To get the URL to access the solution via terminal, run the following command. Note that this will be another way to see if the solution is up and running if you do not have access to CircleCI.

    kubectl get service -n test
Your output should look like this if the cluster spin up is successful.
<br>
<img src="readme-images/kubectl_get-service.png" alt="kubectl_check-service" width=60% height=60%>
<br>

Copy the **External-IP** link and insert that into your web browser. You should see this, and the cluster should be successfully up and running.
<br>
<img src="readme-images/solution_working.png" alt="solution_working" width=60% height=60%>
<br>

## Accessing Solution (Distinction task)
### Via CircleCI
Opening up the Smoke Test step in the deploy-prod job should give you the link to access the solution.
<br>
<img src="readme-images/di-load-balancer_smoke-test.png" alt="di-lb_smoke-test" width=70% height=70%>
<br>

### Via terminal (kubectl)
Alternatively, you can also run the following command to also get the link

    kubectl get service -n prod
<img src="readme-images/di-kubectl_get-service.png" alt="di-kubectl_check-service" width=60% height=60%>
<br>

## How to tear down the solution
To tear down the solution, you will need to run several commands to destory and shut down the application.
<br>

Before starting, open up the **Project Settings** in your CircleCI pipeline repository, and press the **Unfollow Project** button. This will make sure the solution does not get deployed again unless it is needed to be redeployed.
<img src="readme-images/circleci-unfollow.png" alt="circleci-unfollow" width=50% height=50%>
<br>

<br>
First run the following command to destroy the namespace

    make namespace-down
<img src="readme-images/namespace_down.png" alt="namespace_down" width=50% height=50%>
<br>

You will then need to open up the DocumentDB cluster page (https://console.aws.amazon.com/docdb/home?region=us-east-1#clusters), tick the **todo-db-test-docdb-cluster**, press the **Actions** button, then select the **Delete** button. Do this as well for the **todo-db-prod-docdb-cluster**.
<br>
<img src="readme-images/destroy_docdb1.png" alt="destroy_docdb" width=50% height=50%>
<br>

You will get a prompt to ensure you are wanting to delete the cluster, select **No**, tick the box below and enter `delete entire cluster`. Once you delete it, you will need to wait a bit until it deletes before you can continue.
<br>
<img src="readme-images/destroy_docdb2.png" alt="destroy_docdb" width=40% height=40%>
<br>

Next open up the DocumentDB Subnet groups page (https://console.aws.amazon.com/docdb/home?region=us-east-1#subnetGroups), then select the **todo-db-test-db-subnet-group**, press the **Actions** button, then select the **Delete** button. Do this as well for the ****todo-db-prod-db-subnet-group**.
<br>
<img src="readme-images/destroy_docdb3.png" alt="destroy_docdb" width=60% height=60%>
<br>
<img src="readme-images/destroy_docdb4.png" alt="destroy_docdb" width=40% height=40%>
<br>

Open up the Security Groups page in the VPC service (https://console.aws.amazon.com/vpc/home?region=us-east-1#securityGroups:), then select the sec groups that's named **Allow MongoDB Port** (security group names: **todo-db-test-sg** and **todo-db-prod-sg**), open the **Actions** dropdown, then select **Delete security groups**. Then press the **Delete** button on the prompt.
<br>
<img src="readme-images/destroy_docdb5.png" alt="destroy_docdb" width=60% height=60%>
<br>
<img src="readme-images/destroy_docdb6.png" alt="destroy_docdb" width=40% height=40%>
<br>

After deleting the DocumentDB stuff, run the command `helm list -A` to see the name(s) of deployed application(s).
<br>
<img src="readme-images/helm1.png" alt="helm" width=60% height=60%>
<br>

The following image will be in relation to when the prod version also gets deployed (Please Refer to that part [here](#Distinction-Task))
<br>
<img src="readme-images/helm1-1.png" alt="helm" width=60% height=60%>
<br>

Once you find out the name(s) of the application(s), run the following command to uninstall the deployed application.

    helm uninstall <name> -n <namespace>
    e.g. 
    helm uninstall todo -n test
    helm uninstall todo -n prod
<img src="readme-images/helm2.png" alt="helm" width=40% height=40%>
<br>

Finally run the following command to delete everything that is left (***Please note that this will take some time***).

    make kube-delete-cluster
This should be the final lines before it completes, that means the cluster and the site is fully destroyed.
<br>
<img src="readme-images/kube-down.png" alt="kube-down" width=40% height=40%>
<br>

# Simple Todo App with MongoDB, Express.js and Node.js
The ToDo app uses the following technologies and javascript libraries:
* MongoDB
* Express.js
* Node.js
* express-handlebars
* method-override
* connect-flash
* express-session
* mongoose
* bcryptjs
* passport
* docker & docker-compose

## What are the features?
You can register with your email address, and you can create ToDo items. You can list ToDos, edit and delete them. 

# How to use
First install the depdencies by running the following from the root directory:
```
npm install --prefix src/
```

To run this application locally you need to have an insatnce of MongoDB running. A docker-compose file has been provided in the root director that will run an insatnce of MongoDB in docker. TO start the MongoDB from the root direction run the following command:

```
docker-compose up -d
```

Then to start the application issue the following command from the root directory:
```
npm run start --prefix src/
```

The application can then be accessed through the browser of your choise on the following:

```
localhost:5000
```
## Container
A Dockerfile has been provided for the application if you wish to run it in docker. To build the image, issue the following commands:

```
cd src/
docker build . -t todoapp:latest
```

## Terraform

### Bootstrap
A set of bootstrap templates have been provided that will provision a DynamoDB Table, S3 Bucket & Option Group for DocumentDB & ECR in AWS. To set these up, ensure your AWS Programmatic credentials are set in your console and execute the following command from the root directory

```
make bootstrap
```

### To instantiate and destroy your TF Infra:

To instantiate your infra in AWS, ensure your AWS Programattic credentials are set and execute the following command from the root infra directory:

```
make up -e ENV=<environment_name>
```

Where environment_name is the name of the environment that you wish to manage.

To destroy the infra already deployed in AWS, ensure your AWS Programattic credentials are set and execute the following command from the root directory:

```
make down -e ENV=<environment_name>
```

## Testing

Basic testing has been included as part of this application. This includes unit testing (Models Only), Integration Testing & E2E Testing.

### Linting:
Basic Linting is performed across the code base. To run linting, execute the following commands from the root directory:

```
npm run test-lint --prefix src/
```

### Unit Testing
Unit Tetsing is performed on the models for each object stored in MongoDB, they will vdaliate the model and ensure that required data is entered. To execute unit testing execute the following commands from the root directory:

```
npm run test-unit --prefix src/
```

### Integration Testing
Integration testing is included to ensure the applicaiton can talk to the MongoDB Backend and create a user, redirect to the correct page, login as a user and register a new task. 

Note: MongoDB needs to be running locally for testing to work (This can be done by spinning up the mongodb docker container).

To perform integration testing execute the following commands from the root directory:

```
npm run test-integration --prefix src/
```


###### This project is licensed under the MIT Open Source License
