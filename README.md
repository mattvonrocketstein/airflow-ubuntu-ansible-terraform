# 1. Running the Demo

## 1.1 Prerequisites

1.1.1 Valid named AWS profiles should already be setup in your `~/.aws/credentials` file.  We'll assume in the rest of this guide that the profile you want to use is called `MY_PROFILE`.  The correct format for the entry is as follows:

    [MY_PROFILE]
    aws_access_key_id=REDACTED
    aws_secret_access_key=REDACTED


1.1.2 You'll also need local copies of `terraform`, `ansible`, and `jq`.  Recent versions in general should work fine, but for your consideration my (confirmed working) version info follows:

    $ terraform --version
    Terraform v0.9.11

    $ ansible --version
    ansible 2.3.2.0

    $ jq --version
    jq-1.5

Installation instructions/downloads can be found [here for terraform](https://www.terraform.io/downloads.html), [here for ansible](http://docs.ansible.com/ansible/latest/intro_installation.html) and [here for jq](https://stedolan.github.io/jq/download/).  More to the point, ansible can be installed easily with `pip install ansible==2.3.2.0`, and jq with `brew install jq`

Briefly, `terraform` is responsible for creating infrastructure, `ansible` for provisioning infrastructure, and the `jq` tool helps parse JSON output from terraform to provide input for ansible.

## 1.2 Usage

You can bootstrap the infrastructure with the commands you see below.  Provisioning is mostly idempotent, so you can feel free to run it more than once.

1.2.1. **Create keys** with `make keypair`.

1.2.2. **Create infrastructure** with `make infrastructure`

1.2.3. **Provision infrastructure** with `make provision`.  You can see the server IP address in this step, which you'll want to use later for checking out the airflow web UI.

1.2.4. (Optional) **Test infrastructure** with `make test`.

1.2.5. (Optional) **Inspect server** in place with `make ssh`

1.2.6. **Teardown infrastructure** with `make teardown`.

# 2. Design & Technology Decisions

## 2.1 Layout & Abstraction

This project layout is something I've had a lot of success with as far as on-boarding people who are not familiar with terraform and ansible.  It's optimized for simplicity, readability, and maintainability, whereas perfection in modularity is less of priority.  

In particular I've avoided writing [ansible roles](https://www.digitalocean.com/community/tutorials/how-to-use-ansible-roles-to-abstract-your-infrastructure-environment) and [terraform modules](https://www.terraform.io/docs/modules/usage.html) since these add complexity, especially for new-comers.  For some projects this may not be possible or may not be a good idea but for prototyping, proofs-of-concept and bootstrapping an inclusive DevOps environment I've found that the KISS philosophy (keep it simple, stupid) goes a long way.

## 2.2 Makefile

Makefile based automation is not my favorite thing, but in a world with Gulpfiles, Rakefiles, Fabfiles, and many other options for project automation, Makefile's feel like a lightweight and mostly dependency-free approach.  It's nice that any Jenkins instance or development environment already has `make`.  It also has the benefit that it doesn't commit itself to a Python/Ruby/JS preference, which in my experience polyglot development shops tend to appreciate.

## 2.3 Terraform

Terraform is a declarative resource description language that can help to build infrastructure on the cloud.  There are other ways of accomplishing this, but using terraform is not a very difficult or controversial choice to make. Particularly if you care about maybe being cloud agnostic at some point in the future, it seems to be the best option in the space.

One thing that is controversial is that I'm not setting up [remote state](https://www.terraform.io/docs/state/remote.html).  For real projects this would be important but in this case it would only distract from the rest of my implementation.  I'm also not using [terraform modules](https://www.terraform.io/docs/modules/usage.html) for the reasons mentioned previously.

## 2.4 Ansible

Anything else would work fine for a small project, but Ansible is my favorite CM language for a few reasons.   

2.4.1. Ansible is agent-free and requires no central server.  

2.4.2. Any dev or sysadmin can pretty much read it and write it after a very brief introduction (the important thing is to already have patterns in place for project layout and invocation).

2.4.3. The `ansible-vault` tool provides a lightweight, built-in approach to dealing with secrets.  This is crucial for shops that want to handle infrastructure responsibly but don't have the time to setup a better solution with something like consul or hashicorp's vault.

## 2.5 Docker-compose

Normally `docker-compose` is my weapon of choice for describing and deploying service ensembles.  In this case the prexisting work at [docker-airflow](https://github.com/puckel/docker-airflow) made using docker-compose an easy win.. this is exactly what I would have wanted to build and almost all the work was already done.  

In general though using docker-compose has several benefits:

2.5.1. As a manifest for service ensembles, docker-compose makes dependencies and other relationships between services clear and easy to read.

2.5.2. Local development looks exactly like production if/when that's useful for developers.

2.5.3. Running complex integration tests entirely inside Jenkins (or whatever CI environment) becomes possible with no extra effort thanks to docker's sandboxing of i.e. networking and filesystems.  Suppose you want to upgrade the database version without the webserver or vice versa.  The utility of running such an integration suite on test branch instead of a whole test environment is hard to overstate!

2.5.4. The format preserves fairly well our ability to pivot on deployment style at any point.  For example switching to kubernetes or ECS-based deployments should be easy.

# 3. Assumptions, Tradeoffs, Room for Improvement

This process is not bad, but there's lots of room for improvement.  A few things that stand out:

3.1. Due to the benefits of docker-compose I've already mentioned, we're currently hosting all the airflow components on one server.  This might seem bad but is actually probably ok, especially for demonstration/evaluation purposes.  I'm not an expert on airflow, but as a workflow orchestration engine, I would expect that airflow itself should basically be doing book-keeping and would leave the truly hard stuff to separate worker hosts.

3.2. It's often better to deploy infrastructure from images (i.e. use [packer](https://www.packer.io/intro/index.html) to build an AMI).  We avoid truly immutable infrastructure here for simplicity's sake, because it would take our two stage process (build infrastructure, provision infrastructure) to at least a 4 stage process (build infrastructure, provision infrastructure, snapshot infrastructure to image, deploy image).

3.3. For the reasons I've already covered, I try to avoid advanced features of ansible/terraform whenever possible until I know the good folks doing my code reviews are up to speed.

3.4. Despite the work that projects like [docker-airflow](https://github.com/puckel/docker-airflow) save us, they create new work too.  For real production usage, best practice would be to setup a private docker repository to guarantee image integrity, and to do a thorough code review/evaluation of images before using them.

3.5. For simplicity, my deployments do *not* use VPCs or bastion hosts; obviously this is something that you probably always want in real life.
