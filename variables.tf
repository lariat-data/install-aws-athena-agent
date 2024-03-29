variable "lariat_api_key" {
  type = string
}

variable "lariat_application_key" {
  type = string
}

variable "lariat_sink_aws_access_key_id" {
  type = string
}

variable "lariat_sink_aws_secret_access_key" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "backfill_interval_cron" {
  type = string
  default = "rate(45 minutes)"
}

variable "query_dispatch_interval_cron" {
  type = string
  default = "rate(5 minutes)"
}

variable "s3_query_results_bucket" {
  type = string
  default = "lariat-athena-default-query-results"
}

variable "s3_agent_config_bucket" {
  type = string
  default = "lariat-athena-default-config"
}

variable "lariat_output_bucket" {
  type = string
  default = "lariat-batch-agent-sink"
}

variable "lariat_vendor_tag_aws" {
  type = string
  default = ""
}

variable "lariat_ecr_image_name" {
  type = string
  default = "lariat-athena-agent"
}
