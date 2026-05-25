/*
  This module sets up a Network Load Balancer (NLB) to expose an RDS Serverless cluster privately within a VPC. 
  It creates the necessary resources to allow internal access to the RDS Serverless cluster via PrivateLink.

resource "aws_lb" "postgres_serverless_nlb" {
  name               = "mvsh-pg-serverless-nlb-${var.environment}"
  internal           = true
  load_balancer_type = "network"

  subnets                          = var.multi_az_nat ? var.private_subnet_ids : [var.private_subnet_ids[0]]
  enable_cross_zone_load_balancing = var.multi_az_nat

  tags = merge(
    {
      Name        = "mvsh-pg-serverless-nlb-${var.environment}",
      Environment = var.environment,
      Component   = "Serverless-PrivateLink",
    },
    var.tags,
  )
}

resource "aws_lb_target_group" "postgres_serverless_tg" {
  name        = "mvsh-pg-serverless-tg-${var.environment}"
  port        = 5432
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group_attachment" "postgres_serverless_attachment" {
  target_group_arn = aws_lb_target_group.postgres_serverless_tg.arn
  target_id        = data.dns_a_record_set.postgres_internal_ip.addrs[0]
  port             = 5432
}

resource "aws_lb_listener" "postgres_serverless_listener" {
  load_balancer_arn = aws_lb.postgres_serverless_nlb.arn
  port              = 5432
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.postgres_serverless_tg.arn
  }
}

resource "aws_vpc_endpoint_service" "postgres_serverless_service" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.postgres_serverless_nlb.arn]

  tags = merge(
    {
      Name        = "mvsh-pg-serverless-nlb-${var.environment}",
      Environment = var.environment,
      Component   = "Serverless-PrivateLink",
    },
    var.tags,
  )
}
*/