## Deploying a go app to ECS
### With Terraform and whole lot of finger crossing

#### Follow me on my adventure:

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

I'll end this section with a thank you. It might seem weird to thank a company for the opportunity to take a tech challenge, but for me it gives me insight into how much I can accomplish and learn in a small time frame. So I'm thankful for the push! 

### So, how did I get here...

#### Terraform we meet again
I'm fairly comfortable with the basics of Terraform, but overall I haven't had a lot of experience on large projects, or setting up a deployment from scratch. I've worked on small debugging tasks and API updates for Azure, GCP and some AWS.  

I understand the principles of connecting to providers, and using their APIs to provision and deploy products in theory. In practice however I will defnitely benefit on a team who I can learn and grow with!

So starting from the beginning:

##### Steps:
[Setting up my provider](#step-1-setting-up-my-provider)
[Adding variables](#step-2-adding-variables)
[Adding Cloudwatch for some basic monitoring](#step-3-cloudwatch-for-basic-monitoring)
[Setting up the VPC](#step-4-setting-up-the-vpc)
[Adding Security Groups](#step-5-security-groups)
[Creating my ECR repo](#step-6-creating-the-ecr-repo)
[Setting up a load balancer](#step-7-adding-a-load-balancer)
[Setting up my ECS cluster](#step-8-finally-provisioning-the-ecs-cluster)

#### Step 1 Setting up my Provider

I started with my `env` folder and with `stage.tf`. My reasoning is that eventually I'd like to have steps for different environments so I would like to run different tasks based on the environment passed in by my pipeline.

In `stage.tf` is where I put my provider connection as well as my backend to store project state. In this case using AWS as the provider, and S3 as the backend. 

The custom module came later on as I realized I wanted to organize my code a little better so we could use different environments so my understanding is this is like an entrypoint for Terraform after finising with this step.
[back to steps](#steps)

#### Step 2 Adding variables
After setting up my provider I eventually organized my infrastructure into the folders `definitions`, `scrips`, `task-definitions`, to go with my `env` folder.

In `definitions` I created `variables.tf`. I don't have a `tfvars` file here because my only 'secret' exposed is my account number. My plan was to get things working and then obscure that at a later time. I would not do this on a real world application though! I took that risk here in order to make things work. My AWS credentials are just stored locally so I didn't have to manage any company secrets. I added to `variables.tf` as I went along.
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

This I set up according to the docs, adding an additional timeout value (upping it from the default of 60s to 5m).
[back to steps](#steps)

#### Step 8 Finally provisioning the ECS cluster

Finally the big moment: provisioning my container cluster! Why did I choose ECS instead of EKS? Honestly, who can learn EKS in a few days? Kubernetes is a lifelong journey (a short one but still...). I'm still in the phase of trying to setup a cluster on bare metal at home so I can try to get a hands on understanding of all the moving parts. I know that starting with the deep dive vs getting stuck in with services that make using a platform easier isn't always the best approach when in the real world. Sometimes you have to get things out the door first. But personally I do like trying to do a deep dive on technology that I'm responsible for (ideally before being responsible for it!). Espcially one as complicated as Kubernetes. There are a lot of ways to make mistakes managing a cluster even if you're using a managed service! I want to be ready to create hardened infrastructure when I get my chance to!

I initialize the cluster and name it, create a data source so my task definition template (in `task_definitions`) can be set up for the cluster, then finally create my ECS service. Connecting other moving parts like my load balancer, security groups, and my account's public subnet. 

So here is where I hit a wall. I've followed documentation, I've read blog posts and creeped on code on Github. But I'm not successful in getting my `terraform plan` green on this step. So currently I'm deep in the AWS/Terraform docs trying to make sense of what I have set up so far.
[back to steps](#steps) or [back to top](#deploying-a-go-app-to-ecs)






