locals {

app_fullname = format("%s-%s-%s-tg",var.project,var.systemenv,var.function_name)

lambda_alb_target_group_arn =  aws_lb_target_group.target_group[0].arn
}