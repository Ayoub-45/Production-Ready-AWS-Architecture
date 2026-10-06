
########################################
# ALB Security Group
########################################

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for the application load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from the Internet"
    from_port   = var.alb_port
    to_port     = var.alb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from the Internet"
    from_port   = var.https_port
    to_port     = var.https_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}


########################################
# Application Load Balancer
########################################

resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}


########################################
# Target Group
########################################

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-app-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "${var.project_name}-app-tg"
  }
}


########################################
# Auto Scaling Group → Target Group
########################################

resource "aws_autoscaling_attachment" "app" {
  autoscaling_group_name = var.asg_name
  lb_target_group_arn    = aws_lb_target_group.app.arn
}


########################################
# HTTP Listener
########################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type = var.enable_https ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.enable_https ? [1] : []

      content {
        port        = tostring(var.https_port)
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.enable_https ? [] : [1]

      content {
        target_group {
          arn = aws_lb_target_group.app.arn
        }
      }
    }
  }
}


########################################
# ALB → Application Security Group
########################################

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = var.app_security_group_id
  referenced_security_group_id = aws_security_group.alb.id

  from_port = var.app_port
  to_port   = var.app_port

  ip_protocol = "tcp"

  description = "Allow application traffic from the ALB"
}


########################################
# ACM Certificate
########################################

resource "aws_acm_certificate" "app" {
  count = var.enable_https ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cert"
  }
}


########################################
# ACM DNS Validation Record in Cloudflare
########################################

resource "cloudflare_dns_record" "acm_validation" {
  for_each = var.enable_https ? { "app" = true } : {}

  zone_id = var.cloudflare_zone_id

  name = trimsuffix(
    one(aws_acm_certificate.app[0].domain_validation_options).resource_record_name,
    "."
  )

  type = one(
    aws_acm_certificate.app[0].domain_validation_options
  ).resource_record_type

  content = one(
    aws_acm_certificate.app[0].domain_validation_options
  ).resource_record_value

  ttl     = 1
  proxied = false
}


########################################
# ACM Certificate Validation
########################################

resource "aws_acm_certificate_validation" "app" {
  count = var.enable_https ? 1 : 0

  certificate_arn = aws_acm_certificate.app[0].arn

  validation_record_fqdns = [
    trimsuffix(
      one(aws_acm_certificate.app[0].domain_validation_options).resource_record_name,
      "."
    )
  ]

  timeouts {
    create = "10m"
  }
}





########################################
# HTTPS Listener
########################################

resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.app.arn
  port              = var.https_port
  protocol          = "HTTPS"

  ssl_policy      = var.ssl_policy
  certificate_arn = aws_acm_certificate_validation.app[0].certificate_arn

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.app.arn
      }
    }
  }
}


########################################
# Cloudflare → AWS ALB
########################################

resource "cloudflare_dns_record" "app" {
  zone_id = var.cloudflare_zone_id

  name    = "app"
  type    = "CNAME"
  content = aws_lb.app.dns_name

  proxied = true
  ttl     = 1
}

