output "lambda_app_url" {
  value = var.enable_function_url ? aws_lambda_function_url.lambda_app_url[0].function_url : null
}

output "lambda_alb_target_group_arn" {
  value = local.lambda_alb_target_group_arn
}
