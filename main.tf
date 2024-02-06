terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    time = {
      source  = "hashicorp/time"
    }
    null = {
      source  = "hashicorp/null"
    }
  }
  backend "s3" {}

}

locals {
    today  = timestamp()
    lambda_heartbeat_time   = timeadd(local.today, "5m")
    lambda_heartbeat_minute = formatdate("m", local.lambda_heartbeat_time)
    lambda_heartbeat_hour = formatdate("h", local.lambda_heartbeat_time)
    lambda_heartbeat_day = formatdate("D", local.lambda_heartbeat_time)
    lambda_heartbeat_month = formatdate("M", local.lambda_heartbeat_time)
    lambda_heartbeat_year = formatdate("YYYY", local.lambda_heartbeat_time)
    lariat_vendor_tag_aws = var.lariat_vendor_tag_aws != "" ? var.lariat_vendor_tag_aws : "lariat-${var.aws_region}"
}

provider "time" {}
provider "null" {}

# Configure default the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      VendorLariat = local.lariat_vendor_tag_aws
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "lariat_athena_agent_config_bucket" {
  bucket_prefix = var.s3_agent_config_bucket
  force_destroy = true
}

resource "aws_s3_bucket" "lariat_athena_query_results_bucket" {
  bucket_prefix = var.s3_query_results_bucket
  force_destroy = true
}

resource "aws_s3_object" "lariat_athena_agent_config" {
  bucket = aws_s3_bucket.lariat_athena_agent_config_bucket.bucket
  key    = "athena_agent.yaml"
  source = "athena_agent.yaml"

  etag = filemd5("athena_agent.yaml")
}

data "aws_iam_policy_document" "lariat_athena_agent_repository_policy" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lariat_athena_monitoring_policy" {
  name_prefix = "lariat-athena-monitoring-policy"
  policy = templatefile("iam/lariat-athena-monitoring-policy.json.tftpl", { s3_query_results_bucket = aws_s3_bucket.lariat_athena_query_results_bucket.bucket, s3_agent_config_bucket = aws_s3_bucket.lariat_athena_agent_config_bucket.bucket, aws_account_id = data.aws_caller_identity.current.account_id })
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lariat_athena_monitoring_lambda_role" {
  name_prefix = "lariat-athena-monitoring-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
  managed_policy_arns = [aws_iam_policy.lariat_athena_monitoring_policy.arn, "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

# This resource will destroy (potentially immediately) after null_resource.next
resource "null_resource" "previous" {}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [null_resource.previous]

  create_duration = "30s"
}

resource "aws_athena_workgroup" "lariat_athena_workgroup" {
  name = "lariat"
  force_destroy = true
}

resource "aws_lambda_function" "lariat_athena_monitoring_lambda" {
  depends_on = [time_sleep.wait_30_seconds]

  function_name = "lariat-athena-monitoring-lambda"
  image_uri = "358681817243.dkr.ecr.${var.aws_region}.amazonaws.com/lariat-athena-agent:latest"
  role = aws_iam_role.lariat_athena_monitoring_lambda_role.arn
  package_type = "Image"
  memory_size = 512
  timeout = 900

  environment {
    variables = {
      S3_QUERY_RESULTS_BUCKET = aws_s3_bucket.lariat_athena_query_results_bucket.bucket
      LARIAT_API_KEY = var.lariat_api_key
      LARIAT_APPLICATION_KEY = var.lariat_application_key
      CLOUD_AGENT_CONFIG_PATH = "${aws_s3_bucket.lariat_athena_agent_config_bucket.bucket}/athena_agent.yaml"
      LARIAT_ATHENA_WORKGROUP = "${aws_athena_workgroup.lariat_athena_workgroup.id}"
      LARIAT_OUTPUT_BUCKET = var.lariat_output_bucket

      LARIAT_SINK_AWS_ACCESS_KEY_ID = "${var.lariat_sink_aws_access_key_id}"
      LARIAT_SINK_AWS_SECRET_ACCESS_KEY = "${var.lariat_sink_aws_secret_access_key}"

      LARIAT_CLOUD_ACCOUNT_ID = "${data.aws_caller_identity.current.account_id}"
      LARIAT_ENDPOINT = "http://ingest.lariatdata.com/api"
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "lariat_athena_monitoring_lambda_config" {
  function_name = aws_lambda_function.lariat_athena_monitoring_lambda.function_name
  maximum_retry_attempts = 0
}

resource "aws_cloudwatch_event_rule" "lariat_athena_lambda_trigger_5_minutely" {
  name_prefix = "lariat-athena-lambda-trigger"
  schedule_expression = var.query_dispatch_interval_cron
}

resource "aws_cloudwatch_event_rule" "lariat_athena_lambda_trigger_daily" {
  name_prefix = "lariat-athena-lambda-trigger"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_rule" "lariat_athena_backfill_lambda_trigger" {
  name_prefix = "lariat-athena-lambda-trigger"
  schedule_expression = var.backfill_interval_cron
}

resource "aws_cloudwatch_event_target" "lariat_athena_lambda_trigger_5_minutely_target" {
  rule = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_5_minutely.name
  arn = aws_lambda_function.lariat_athena_monitoring_lambda.arn
  input = jsonencode({"run_type"="batch_agent_query_dispatch"})
}

resource "aws_cloudwatch_event_target" "lariat_athena_lambda_trigger_daily_target" {
  rule = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_daily.name
  arn = aws_lambda_function.lariat_athena_monitoring_lambda.arn
  input = jsonencode({"run_type"="raw_schema"})
}

resource "aws_cloudwatch_event_target" "lariat_athena_backfill_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.lariat_athena_backfill_lambda_trigger.name
  arn = aws_lambda_function.lariat_athena_monitoring_lambda.arn
  input = jsonencode({"run_type"="backfill_batch_agent_query_dispatch"})
}

resource "aws_cloudwatch_event_rule" "lariat_athena_lambda_trigger_heartbeat" {
  name_prefix = "lariat-athena-lambda-trigger"
  schedule_expression ="cron(${local.lambda_heartbeat_minute} ${local.lambda_heartbeat_hour} ${local.lambda_heartbeat_day} ${local.lambda_heartbeat_month} ? ${local.lambda_heartbeat_year})"
}

resource "aws_cloudwatch_event_target" "lariat_athena_lambda_trigger_heartbeat_target" {
  rule = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_heartbeat.name
  arn = aws_lambda_function.lariat_athena_monitoring_lambda.arn
  input = jsonencode({"run_type"="raw_schema"})
}

resource "aws_cloudwatch_event_rule" "lariat_athena_lambda_trigger_upload" {
  name_prefix = "lariat-athena-lambda-trigger-upload"
  event_pattern = templatefile("cloudwatch/athena_event_trigger.tftpl", { lariat_athena_workgroup = aws_athena_workgroup.lariat_athena_workgroup.id })
}

resource "aws_cloudwatch_event_target" "lariat_athena_lambda_trigger_upload_target" {
  rule = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_upload.name
  arn = aws_lambda_function.lariat_athena_monitoring_lambda.arn

  input_transformer {
    input_paths = {
      previous_state = "$.detail.previousState"
      workgroup_name = "$.detail.workgroupName"
      detail-type = "$.detail-type"
      current_state = "$.detail.currentState"
      query_execution_id = "$.detail.queryExecutionId"
    }
    input_template = <<EOF
{
  "run_type": "batch_agent_copy",
  "detail": {
    "previousState": "<previous_state>",
    "currentState": "<current_state>",
    "queryExecutionId": "<query_execution_id>",
    "workgroupName": "<workgroup_name>"
  },
  "detail-type": "<detail-type>"
}
EOF
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_5_minutely" {
  statement_id  = "AllowExecutionFromCloudWatch5Minutely"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lariat_athena_monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_5_minutely.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_daily" {
  statement_id  = "AllowExecutionFromCloudWatchDaily"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lariat_athena_monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_daily.arn
}


resource "aws_lambda_permission" "allow_cloudwatch_heartbeat" {
  statement_id  = "AllowExecutionFromCloudWatchHeartbeat"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lariat_athena_monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_heartbeat.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_upload" {
  statement_id  = "AllowExecutionFromCloudWatchUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lariat_athena_monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_upload.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_backfill" {
  statement_id  = "AllowExecutionFromCloudWatchBackfill"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lariat_athena_monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lariat_athena_backfill_lambda_trigger.arn
}

data "aws_iam_policy_document" "allow_access_from_lariat_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["358681817243",
      "arn:aws:sts::358681817243:assumed-role/lariat-iam-terraform-cross-account-access-role-${data.aws_caller_identity.current.account_id}/s3-session-${data.aws_caller_identity.current.account_id}"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.lariat_athena_query_results_bucket.arn,
      "${aws_s3_bucket.lariat_athena_query_results_bucket.arn}/*",

    ]
  }
}

data "aws_iam_policy_document" "allow_config_access_from_lariat_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["358681817243",
      "arn:aws:sts::358681817243:assumed-role/lariat-iam-terraform-cross-account-access-role-${data.aws_caller_identity.current.account_id}/s3-session-${data.aws_caller_identity.current.account_id}"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.lariat_athena_agent_config_bucket.arn,
      "${aws_s3_bucket.lariat_athena_agent_config_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_lariat_account_policy" {
  bucket = aws_s3_bucket.lariat_athena_query_results_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_lariat_account.json
}

resource "aws_s3_bucket_policy" "allow_config_access_from_lariat_account_policy" {
  bucket = aws_s3_bucket.lariat_athena_agent_config_bucket.id
  policy = data.aws_iam_policy_document.allow_config_access_from_lariat_account.json
}
