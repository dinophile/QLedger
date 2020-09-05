## Deploying a go app to ECS
### With Terraform and whole lot of finger crossing

#### Follow me on my adventure:

#### [Update 1](#update-1) Sept 3, 2020
#### [Update 2](#update-2) Sept 4, 2020 

Wherein I explain my decisions, if you're interested only in the steps I took working with Terraform skip to that [section](#so-how-did-i-get-here)!

I wanted to build out a solution fully in Terraform since writing `tf` files from scratch and deploying to ECS isn't something I'm familiar with!

I could have deployed to Heroku fairly easily but no, I decided now was a great time to challenge myself! (And to be fair, it was! I have learned more than I knew last week so still a win in my books!)

My first step was stretching myself and using the Qledger app suggestion. I haven't worked with production Go apps yet, so this was a great opportunity.

I first familiarized myself with the code and how I could get it opperational locally. And I can proudly say: It works on my machine! I did have to set up a Postgres docker container locally, and update the connection string to point to my local db. 

I did make one small addition to the code base. In `main.go:33` they use the `Open` method to check if the database is successfully reachable. But this method only checks that your config is correct, it doesn't actually open a connection. There's a lesson in variable naming in there somewhere.

So I added a quick check by connecting to the db using `Ping`. I'm thinking it might make a good PR, but I'm also looking to see if there are any reasons why `Open` was used instead. It would have saved me some time debugging the connection to Postgres if it was paired with `Ping`! Ah well, hindsight.

So after running it locally I then built and ran the Qledger docker connecting to my Postgres container (using `docker build -t qledger .` along with `docker run --env-file=docker.env qledger`).

I wanted to hand off a solution to you that should have been straight forward to run. Just `terraform init`, `plan` and `apply`. 

It would have been glorious to build my app container (accounting for the RDS Postgres intance endpoint it needed to connect to in `docker.env`), then push that up to ECR, get it on my intented ECS cluster than bask in my victory.

Alas, you can guess how this actually went.

And I doubled down and tried to setup a pipeline in CircleCI. Which to be fair was mostly successful! Minus the key deploying and building phases. But they are on my list of TODOs once I can wrangle Terraform into submission.

A lot of my experience with previous Terraform projects used older APIs with Amazon. So there was a lot of googling to find out how resources should be named and what objects they might be expecting. So I'm glad to have gotten the chance to refresh how to navigate the Terraform and AWS' docs!

So now I will document the steps I took to get this far, and I hope we get a chance to sit down and go over where I went wrong! I am also going to keep going. You can follow along in [Github](https://github.com/dinophile/QLedger)! I know, but try to contain your excitement! 

Note that my `.tf` files are all in the `infrastructure` folder, and that I would never set up a project like this at all! My goal is to separate the code and set up the pipeline to interact with a separate repo to finish the build and deploy steps. 

I'll end this section with a thank you. It might seem weird to thank a company for the opportunity to take a tech challenge, but for me it gives me insight into how much I can accomplish and learn in a small time frame. So I'm thankful for the push! 

### So, how did I get here...

#### Terraform we meet again
I'm fairly comfortable with the basics of Terraform, but overall I haven't had a lot of experience on large projects, or setting up a deployment from scratch. I've worked on small debugging tasks and API updates for Azure, GCP and some AWS.  

I understand the principles of connecting to providers, and using their APIs to provision and deploy products in theory. In practice however I will defnitely benefit on a team who I can learn and grow with!

##### Steps:
1. [Setting up my provider](#step-1-setting-up-my-provider)
2. [Adding variables](#step-2-adding-variables)
3. [Adding Cloudwatch for some basic monitoring](#step-3-cloudwatch-for-basic-monitoring)
4. [Setting up the VPC](#step-4-setting-up-the-vpc)
5. [Adding Security Groups](#step-5-security-groups)
6. [Creating my ECR repo](#step-6-creating-the-ecr-repo)
7. [Setting up a load balancer](#step-7-adding-a-load-balancer)
8. [Setting up my ECS cluster](#step-8-finally-provisioning-the-ecs-cluster)

#### Step 1 Setting up my Provider

I started with my `env` folder and with `stage.tf`. My reasoning is that eventually I'd like to have steps for different environments so I would like to run different tasks based on the environment passed in by my pipeline.

In `stage.tf` is where I put my provider connection as well as my backend to store project state. In this case using AWS as the provider, and S3 as the backend. 

The custom module came later on as I realized I wanted to organize my code a little better so we could use different environments so my understanding is this is like an entrypoint for Terraform after finising with this step.
[back to steps](#steps)

#### Step 2 Adding variables
After setting up my provider I eventually organized my infrastructure into the folders `definitions`, `scrips`, `task-definitions`, to go with my `env` folder.

In `definitions` I created `variables.tf`. ~~I don't have a `tfvars` file here because my only 'secret' exposed is my account number. My plan was to get things working and then obscure that at a later time~~. Nope: I scrubbed the account value from my git history using `git-filter-branch`. I think the risk was somewhat low, but **I should know better**! I would not do this on a real world application though! I took that risk here in order to make things work. My AWS credentials are just stored locally so I didn't have to manage any company secrets. I added to `variables.tf` as I went along.
[back to steps](#steps)

#### Step 3 Cloudwatch for basic monitoring

After setting up my variables I added `cloudwatch.tf`. I've seen this used as basic monitoring for proof of concept projects without getting too bogged down by larger logging platforms, so I've incorporated it here for this one as well. Here I've set it so that logs are named based on their environment and set a retention policy for 3 days.
[back to steps](#steps)

#### Step 4 Setting up the VPC

Time for a VPC! This setup was 100% new to me. I started by adding the `aws_availability_zones` data source so that I can get access to all zones available for my account.

Then I set up my vpc resource, choosing a block of addresses to use. I believe that `enable_dns_support` is already defaulted to true, but `hostnames` is defaulted to false. I could have left off `dns_support` but it feels safe to keep in there!

Then I started with a public subnet, with the intention to go back in to create a private one eventually as well. I have set `az_count` as a variable so that can be managed across the code base. And I set up 8 addresses (leaving the other 8 for when I get to the private subnet). I will not pretend to be totally familiar with the deep details about calculating address lengths at all! Networking is also on my "Keep learning a bit more about this as you go!" list!

Finally I create an internet gateway to my VPC so that traffic can reach it.
[back to steps](#steps)

#### Step 5 Security Groups

Next I set my security groups after setting up the VPC. This is so far off of production level standard though and I'm aware of that! I just wanted this to be as easily accessible 'for now'. And in a production environment I'd lock down ports and and possibly IP addresses for ingress and egress as well (especially for internal APIs etc).

I've seen an example before that calculated IP ranges based on your desired region and availability zone subnets. I clearly haven't applied that here! I don't have access to that code anymore, but I call it out here because for certain services you might want to do this! Like region blocking to avoid having to comply with GDPR. Not that I condone that of course. 
[back to steps](#steps)

#### Step 6 Creating the ECR repo

Next I set up an ECR repo so that when I finally write the build step I have somewhere to push my app's image! This seems very straightforward, and I added a lifecycle policy to keep the repo from getting clogged up with uneccessary images. I can't imagine AWS _wouldn't_ charge you for storage there and/or that there wouldn't also be limits.
[back to steps](#steps)

#### Step 7 Adding a load balancer

Next came the load balancer. Using V2 of ELB, I set up an application load balancer. I understand that compared to the network load balancer you get a little more access to network traffic as it comes in so you can do additional routing. Also everything I read for setting up ECS said "use an application loadbalancer"! 

For my target group I'm starting with an HTTP listener, with the plan to add an SSL listener later on. For production I wouldn't use HTTP, but it's nice to have if you're accessing it internally and HTTP can be faster. The health check will use the existing health route in the app `/ping`.

This I set up according to the docs, adding an additional timeout value (upping it from the default of 60s to 5m).
[back to steps](#steps)

#### Step 8 Finally provisioning the ECS cluster

Finally the big moment: provisioning my container cluster! Why did I choose ECS instead of EKS? Honestly, who can learn EKS in a few days? Kubernetes is a lifelong journey (a short one but still...). I'm still in the phase of trying to setup a cluster on bare metal at home so I can try to get a hands on understanding of all the moving parts. I know that starting with the deep dive vs getting stuck in with services that make using a platform easier isn't always the best approach when in the real world. Sometimes you have to get things out the door first. But personally I do like trying to do a deep dive on technology that I'm responsible for (ideally before being responsible for it!). Espcially one as complicated as Kubernetes. There are a lot of ways to make mistakes managing a cluster even if you're using a managed service! I want to be ready to create hardened infrastructure when I get my chance to!

I initialize the cluster and name it, create a data source so my task definition template (in `task_definitions`) can be set up for the cluster, then finally create my ECS service. Connecting other moving parts like my load balancer, security groups, and my account's public subnet. I also make my `task_definition` file available here as a data source, and note that I'm using the same port for region and host. This is also not production ready, as I believe you'd use different ports for each.

So here is where I hit a wall. I've followed documentation, I've read blog posts and creeped on code on Github. But I'm not successful in getting my `terraform plan` green on this step. So currently I'm deep in the AWS/Terraform docs trying to make sense of what I have set up so far.
[back to steps](#steps) or [back to top](#deploying-a-go-app-to-ecs)


## Update 1

### So here's where I'm at today:

### vpc.tf

Here I've updated the structure a bit with some defaults as a learning excercise, and updated the VPC's route table for my internet gateway. Without this I wasn't making sure traffic that matched my public subnet addresses would reach the gateway. For now the addresses are set to all traffic. I'd like to experiment with changing this to a particular region and test it out.

I've also added my missing private subnet (for internal access to my application).

### nat.tf
If I want my private subnet to communicate with the outside world (maybe for updates etc?) I would set up a net network for one way traffic. Here I just play with the settings for that. Very similar setup to the vpc setting for the public subnet.

### circleci.yml
Ok back to the main task: build this app docker image! Can't have an app with no app!

So here I'm playing with the circle config to start with at least the basics going step by step. After I can confirm a build my next step is to set up and ECR registry using my terraform setup and then push my image there.

Once I can get the image to ECR I'll dig into getting more familiar with and setting up a cluster to run the app on. And I'll need to provision and account for and RDS postgres db for my cluster as well. 

Currently just sitting with yaml syntax errors. But will take a break and return to it after some fresh air. 


## Update 2

So today I spent some time with some infra folks I've worked with before. They managed to help sort out some confusion in my head and I have a better idea of missing pieces now.

Had two code reviews (with the goal of understanding broad concepts vs getting the answers!) both reviews helped me clear up some misunderstandings about how I should structure my code.

I mistakenly thought the goal was to remove the infrastructure folder here and have it running in a separate repo. I'll be honest this was backed up by me not having the experience seeing the dev user's view of the infra code! The projects I've helped on _were_ based in a separate repo but were set up for security, maintainence and updates etc! So that was a missing piece of my understanding! #TheMoreYouKnowEh? So with this in mind my next steps are to add in the terraform init/plan/apply with auto approve to my circle ci config. Then fix my silly syntax errors! 

Great conversations today and I'm thankful I have such a supportive network!

But first a good night's sleep to rest the ol' brain.