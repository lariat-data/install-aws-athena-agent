output "lambda_create_iam_user_name" {
 value = aws_iam_user.lambda_create_user.name
}

output "lambda_create_iam_user_arn" {
 value = aws_iam_user.lambda_create_user.arn
}

output "lambda_create_user_kms_key_arn" {
  value = aws_kms_key.lambda_create_user_kms.arn
}

output "lambda_create_user_iam_policy_id" {
  value = aws_iam_user_policy.lambda_create_user_policy.id
}

output "lariat_athena_agent_config_bucket_id" {
  value = aws_s3_bucket.lariat_athena_agent_config_bucket.id
}

output "lariat_athena_agent_config_bucket_arn" {
  value = aws_s3_bucket.lariat_athena_agent_config_bucket.arn
}

output "lariat_athena_query_results_bucket_id" {
  value = aws_s3_bucket.lariat_athena_query_results_bucket.id
}

output "lariat_athena_query_results_bucket_arn" {
  value = aws_s3_bucket.lariat_athena_query_results_bucket.arn
}

output "lariat_athena_agent_config_s3_object_etag" {
  value = aws_s3_object.lariat_athena_agent_config.etag
}

output "lariat_athena_monitoring_iam_policy_id" {
  value = aws_iam_policy.lariat_athena_monitoring_policy.id
}

output "lariat_athena_monitoring_iam_policy_arn" {
  value = aws_iam_policy.lariat_athena_monitoring_policy.arn
}

output "lariat_athena_monitoring_lambda_iam_role_id" {
  value = aws_iam_role.lariat_athena_monitoring_lambda_role.id
}

output "lariat_athena_monitoring_lambda_iam_role_arn" {
  value = aws_iam_role.lariat_athena_monitoring_lambda_role.arn
}

output "lariat_athena_workgroup_id" {
  value = aws_athena_workgroup.lariat_athena_workgroup.id
}

output "lariat_athena_workgroup_arn" {
  value = aws_athena_workgroup.lariat_athena_workgroup.arn
}

output "lariat_athena_monitoring_lambda_arn" {
  value = aws_lambda_function.lariat_athena_monitoring_lambda.arn
}

output "lariat_athena_monitoring_lambda_version" {
  value = aws_lambda_function.lariat_athena_monitoring_lambda.version
}

output "lariat_athena_lambda_trigger_5_minutely_id" {
  value = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_5_minutely.id
}

output "lariat_athena_lambda_trigger_5_minutely_arn" {
  value = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_5_minutely.arn
}

output "lariat_athena_lambda_trigger_daily_id" {
  value = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_daily.id
}

output "lariat_athena_lambda_trigger_daily_arn" {
  value = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_daily.arn
}

output "lariat_athena_backfill_lambda_trigger_id" {
  value = aws_cloudwatch_event_rule.lariat_athena_backfill_lambda_trigger.id
}

output "lariat_athena_backfill_lambda_trigger_arn" {
  value = aws_cloudwatch_event_rule.lariat_athena_backfill_lambda_trigger.arn
}

output "lariat_athena_lambda_trigger_heartbeat_id" {
  value = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_heartbeat.id
}

output "lariat_athena_lambda_trigger_heartbeat_arn" {
  value = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_heartbeat.arn
}

output "lariat_athena_lambda_trigger_upload_id" {
  value = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_upload.id
}

output "lariat_athena_lambda_trigger_upload_arn" {
  value = aws_cloudwatch_event_rule.lariat_athena_lambda_trigger_upload.arn
}
