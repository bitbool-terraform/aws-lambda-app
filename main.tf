data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "iam_for_lambda" {
  name               = format("%s-%s-%s",var.project,var.systemenv,var.function_name)
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}


resource "aws_lambda_function" "lambda_app" {
    function_name = format("%s-%s-%s",var.project,var.systemenv,var.function_name)
    package_type  = "Image"
    role          = aws_iam_role.iam_for_lambda.arn
    image_uri     = var.image_uri
    handler       = var.handler
    architectures = var.architectures
    memory_size   = var.memory_size

    environment {
        variables = var.environment
  }

    ephemeral_storage {
        size = var.ephemeral_storage
    }
}


resource "aws_lambda_function_url" "lambda_app_url" {

    count = var.enable_function_url ? 1 : 0

    function_name      = aws_lambda_function.lambda_app.function_name
    authorization_type = var.authorization_type
    invoke_mode        = var.invoke_mode
}



resource "aws_lb_target_group" "target_group" {

  count = var.enable_alb_target ? 1 : 0

  name        = local.app_fullname
  target_type = "lambda"
  vpc_id      = var.vpc_id
  ip_address_type = "ipv4"

#   protocol = "HTTP"
#   protocol_version = "HTTP1"
#   proxy_protocol_v2 = false
  port     = var.port

  load_balancing_algorithm_type = var.load_balancing_algorithm_type

  health_check {
    enabled = true 
    healthy_threshold = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    interval = var.interval
    path = var.path
    port = var.port
    protocol = var.protocol
    timeout = var.timeout
    matcher = var.matcher
  }
  stickiness {
    enabled = var.stickiness_enabled
    cookie_duration = var.stickiness_cookie_duration
    type = var.stickiness_type
  }

}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count = var.enable_alb_target ? 1 : 0

  target_group_arn = aws_lb_target_group.target_group[0].arn
  target_id        = aws_lambda_function.lambda_app.arn

  depends_on = [aws_lambda_permission.allow_alb]
}


resource "aws_lambda_permission" "allow_alb" {
  count = var.enable_alb_target ? 1 : 0

  statement_id  = "AllowExecutionFromALB-${local.app_fullname}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_app.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.target_group[0].arn
}