# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name = "${var.prefix}-alb"
  }
}

# Target Group for Django API
resource "aws_lb_target_group" "api" {
  name        = "${var.prefix}-api-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path_api # Django backend health at /health/
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.prefix}-api-tg"
  }
}

# Target Group for SSR Frontend
resource "aws_lb_target_group" "ssr" {
  name        = "${var.prefix}-ssr-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path_ssr
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.prefix}-ssr-tg"
  }
}

# HTTP Listener - Redirect to HTTPS (cost-free redirect)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener with intelligent routing rules
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  # Default action - send ALL traffic to SSR (Next.js handles routing)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssr.arn
  }
}

# High Priority: API traffic routing
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# High Priority: Django Admin routing
resource "aws_lb_listener_rule" "admin" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/admin/*"]
    }
  }
}

# Medium Priority: Django static files routing
resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }
}

# Medium Priority: Django media files (if you have them)
resource "aws_lb_listener_rule" "media" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 400

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/media/*"]
    }
  }
}

# Lower Priority: SSR Health check routing (for monitoring tools)
resource "aws_lb_listener_rule" "ssr_health" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 500

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssr.arn
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }
}

# Lower Priority: API Health check routing (for monitoring tools)
resource "aws_lb_listener_rule" "api_health" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 550

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/health/"]
    }
  }
}

# Lower Priority: SSR Metrics routing (for monitoring tools)
resource "aws_lb_listener_rule" "ssr_metrics" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 600

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssr.arn
  }

  condition {
    path_pattern {
      values = ["/metrics"]
    }
  }
}

# Associate WAF with the single ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.waf_web_acl_arn
}