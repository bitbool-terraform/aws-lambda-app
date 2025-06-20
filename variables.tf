# variable "project" {}
# variable "systemenv" {}
#variable "aws_region" {}

variable "function_name" {}
variable "image_uri" {}
variable "enable_function_url" { default = false }
variable "enable_alb_target" { default = false }

variable "handler" { default = null }
variable "architectures" { default = ["x86_64"] }
variable "environment" { default = {} }

variable "vpc_id" { default = null }

variable "port" { default = 80 }


variable "healthy_threshold" { default = 2 }
variable "unhealthy_threshold" { default = 5 }
variable "interval" { default = 60 }
variable "path" { default = "/" }
variable "protocol" { default = "HTTP" }

variable "timeout" { default = 3 }
variable "matcher" { default = "200-299" }
variable "load_balancing_algorithm_type" { default = "least_outstanding_requests" }


variable "stickiness_enabled" { default = true }
variable "stickiness_cookie_duration" { default = 86400 }
variable "stickiness_type" { default = "lb_cookie" }

variable "memory_size" { default = 128 }
variable "ephemeral_storage" { default = 512 }


variable "authorization_type" { default = "NONE" }
variable "invoke_mode" { default = "BUFFERED" }

variable "lambda_policies_arns" { default = {} }

variable "enable_vpc_intergration" { default = false }
variable "subnet_ids" { default = [] }

variable "efs_arn" { default = null }
variable "efs_mount" { default = null }
