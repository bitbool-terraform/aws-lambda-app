output "lambda_app_url" {
  value = var.enable_function_url ? aws_lambda_function_url.lambda_app_url[0].function_url : null
}

output "lambda_alb_target_group_arn" {
  value = try(aws_lb_target_group.target_group[0].arn,null)
}
