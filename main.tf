data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "lambda_base" {
  name   = format("lambda-%s-base",var.function_name)
  path   = "/"
  policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "CreateLogGroup",
          "Action": [
            "logs:CreateLogGroup"
          ],
          "Effect": "Allow",
          "Resource": [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          ]
        },
        {
          "Sid": "CreateLogs",
          "Action": [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Effect": "Allow",
          "Resource": [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*"
          ]
        },
     ]
    })

}

resource "aws_iam_role_policy_attachment" "lambda_base" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_base.arn
}


resource "aws_iam_role_policy_attachment" "lambda_policies" {
  for_each = var.lambda_policies_arns

  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = each.value.arn
}


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
  name               = var.function_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}


resource "aws_lambda_function" "lambda_app" {
    function_name = var.function_name
    package_type  = "Image"
    role          = aws_iam_role.iam_for_lambda.arn
    image_uri     = var.image_uri
    handler       = var.handler
    architectures = var.architectures
    memory_size   = var.memory_size
    timeout       = var.timeout

    environment {
        variables = var.environment
    }

    ephemeral_storage {
        size = var.ephemeral_storage
    }

    dynamic "vpc_config" {
      for_each = var.enable_vpc_intergration ? [""] : []

      content {
          subnet_ids         = var.subnet_ids
          security_group_ids = try([aws_security_group.lambda[0].id],null)
      }
    }  

    dynamic "file_system_config" {
      for_each = var.efs_arn != null ? [""] : []

      content {
        arn              = var.efs_arn
        local_mount_path = var.efs_mount
      }
    }  

    depends_on = [aws_iam_role_policy_attachment.lambda_efs]
}


resource "aws_lambda_function_url" "lambda_app_url" {

    count = var.enable_function_url ? 1 : 0

    function_name      = aws_lambda_function.lambda_app.function_name
    authorization_type = var.authorization_type
    invoke_mode        = var.invoke_mode
}



resource "aws_lb_target_group" "target_group" {

  count = var.enable_alb_target ? 1 : 0

  name        = var.function_name
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

  statement_id  = "AllowExecutionFromALB-${var.function_name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_app.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.target_group[0].arn
}



resource "aws_security_group" "lambda" {
  count = var.enable_vpc_intergration ? 1 : 0

  name     = format("lambda-%s",var.function_name)
  vpc_id   = var.vpc_id

  tags = merge({"Name" = format("lambda-%s",var.function_name)})

  egress {
      from_port       = 0
      to_port         = 0
      protocol        = -1
      cidr_blocks     = ["0.0.0.0/0"]
  }  

  lifecycle { ignore_changes = [ingress,egress] }

}

resource "aws_iam_role_policy_attachment" "lambda_efs" {
  count = var.enable_vpc_intergration ? 1 : 0

  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
