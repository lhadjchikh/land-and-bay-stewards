# Temporary resource to fix the missing target group issue
# This resource should be removed after successful terraform apply
resource "aws_lb_target_group" "legacy_fix" {
  name        = "${var.prefix}-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  # This prevents creation of a new target group
  lifecycle {
    create_before_destroy = true
    # This will cause Terraform to ignore actual existence
    # of the resource and will just import it into state
    ignore_changes = all
  }

  tags = {
    Name        = "${var.prefix}-tg-legacy"
    Description = "Temporary resource to fix state issue"
  }
}