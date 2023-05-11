[<img src="https://img.shields.io/docker/v/lariatdata/install-aws-athena-agent/latest">](https://hub.docker.com/repository/docker/lariatdata/install-aws-athena-agent)


## Intro

[Lariat Data](www.lariatdata.com) is a Continuous Data Quality Monitoring Platform to ensure data products don't break even as business logic, input data and infrastructure change.

This repository contains the Docker image and dependencies for installing the Lariat Agent for AWS Athena.

## How it works
This installer uses Terraform, with remote `.tfstate` files, to create and manage infrastructure in the target cloud account and data source.

## Configuration
This image requires the following configuration values to be injected as environment variables:
- `AWS_REGION` - The target AWS region for the installation. Generally, this should be the same AWS region where target Athena databases live e.g. `us-east-1`
- `AWS_ACCOUNT_ID` - A 12-digit AWS Account Identifier
- `AWS_ACCESS_KEY_ID` - The AWS Access Key ID for a user with privileges to run the installation
- `AWS_SECRET_ACCESS_KEY` - The AWS Secret Access Key for a user with privileges to run the installation
- `AWS_SESSION_TOKEN` - (_optional_) The AWS Session Token for the same user, if required to authenticate with AWS
- `LARIAT_API_KEY` - A Lariat API Key. You can retrieve this from the [`API Keys`](https://app.lariatdata.com/user/keys) page in your Lariat account
- `LARIAT_APPLICATION_KEY` - A Lariat Application Key. You can retrieve this from the [`API Keys`](https://app.lariatdata.com/user/keys) page in your Lariat account

Additionally this image requires a valid YAML configuration file for Athena to be mounted at `/workspace/athena_agent.yaml`. Read more about this configuration file [here](https://docs.lariatdata.com/fundamentals/configuration/configuring-the-aws-athena-agent)

## Building locally
You may build and run a local version of this image using `docker`.

```docker
docker build -t <my_image_name> .
```

## Running locally

### Install the agent
The required configuration values may be passed in during `docker run`, for example:

```docker
docker run -it \
--mount type=bind,source=/path/to/my/athena_agent.yaml,target=/workspace/athena_agent.yaml,readonly \
-e AWS_REGION=<my_aws_region> \
-e AWS_ACCOUNT_ID=<aws_account_id> \
-e AWS_ACCESS_KEY_ID=<aws_access_key_id> \
-e AWS_SECRET_ACCESS_KEY=<aws_secret_access_key> \
-e LARIAT_API_KEY=<lariat_api_key> \
-e LARIAT_APPLICATION_KEY=<lariat_application_key> \
lariatdata/install-aws-athena-agent:latest
```

If you have [awscli](https://aws.amazon.com/cli/) installed, you may prefer to pass in your AWS credentials via command substitution, for example:
```
-e AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
-e AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
```

### Uninstall the agent
The required configuration values may be passed in during `docker run`, for example:

```docker
docker run -it \
--mount type=bind,source=/path/to/my/athena_agent.yaml,target=/workspace/athena_agent.yaml,readonly \
-e AWS_REGION=<my_aws_region> \
-e AWS_ACCOUNT_ID=<aws_account_id> \
-e AWS_ACCESS_KEY_ID=<aws_access_key_id> \
-e AWS_SECRET_ACCESS_KEY=<aws_secret_access_key> \
-e LARIAT_API_KEY=<lariat_api_key> \
-e LARIAT_APPLICATION_KEY=<lariat_application_key> \
lariatdata/install-aws-athena-agent:latest uninstall
```
