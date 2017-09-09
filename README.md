# 1. Running the Demo

## 1.1 Prerequisites

Valid named AWS profiles should already be setup in your `~/.aws/credentials` file.  We'll assume in the rest of this guide that the profile you want to use is called `MY_PROFILE`.  The correct format for the entry is as follows:

    [MY_PROFILE]
    aws_access_key_id=REDACTED
    aws_secret_access_key=REDACTED


You'll also need local copies of `terraform`, `ansible`, and `jq`.  My (confirmed working) version info follows:

    $ terraform --version
    Terraform v0.9.11

    $ ansible --version
    ansible 2.3.2.0

    $ jq --version
    jq-1.5

Briefly, `terraform` is responsible for creating infrastructure, `ansible` for provisioning infrastructure, and the `jq` tool parses JSON.

# 2. Design Decisions

## Makefile

Makefile based automation is not my favorite thing, but in a world with Gulpfiles, Rakefiles, Fabfiles, and many other options for project automation, Makefile's feel like a lightweight and mostly dependency-free approach.  It also has the benefit that it doesn't commit itself to a Python/Ruby/JS preference, which in my experience polyglot development shops tend to appreciate.

## Terraform

Terraform is a declarative resource description language that can help to build infrastructure on the cloud.  There are other ways of accomplishing this, but using terraform is not a very difficult or controversial choice to make. Particularly if you care about maybe being cloud agnostic at some point in the future, it seems to be the best option in the space.

One thing that is controversial is that I'm not setting up [remote state](https://www.terraform.io/docs/state/remote.html).  For real projects this would be important but in this case it would only distract from the rest of my implementation.  I'm also not using [terraform modules](https://www.terraform.io/docs/modules/usage.html), just because it's easy enough to add later and would be overkill for a proof of concept like this where we don't expect to instantiate multiple airflow servers in multiple dev/test/prod environments.

## Ansible

## Docker-compose

# 3. Tradeoffs
