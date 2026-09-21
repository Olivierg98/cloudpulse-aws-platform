data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_region" "current" {}
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
locals {
  name           = "${var.project}-${var.environment}"
  azs            = slice(data.aws_availability_zones.available.names, 0, 2)
  https_enabled  = var.certificate_arn != null
  app_subnet_ids = var.use_private_subnets ? aws_subnet.private[*].id : aws_subnet.public[*].id
  registry       = try(split("/", var.app_image)[0], "public.ecr.aws")
}
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = local.name }
}
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.name}-public-${count.index + 1}" }
}
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  tags              = { Name = "${local.name}-private-${count.index + 1}" }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = { Name = "${local.name}-nat" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "alb" {
  name   = "${local.name}-alb"
  vpc_id = aws_vpc.this.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  dynamic "ingress" {
    for_each = local.https_enabled ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}
resource "aws_security_group" "app" {
  name   = "${local.name}-app"
  vpc_id = aws_vpc.this.id
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_iam_role" "instance" {
  name = "${local.name}-instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy" "application_logs" {
  name = "${local.name}-application-logs"
  role = aws_iam_role.instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.app.arn}:*"
    }]
  })
}
resource "aws_iam_role_policy" "database_secret" {
  count = var.enable_database ? 1 : 0
  name  = "${local.name}-database-secret"
  role  = aws_iam_role.instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.database[0].arn
    }]
  })
}
resource "aws_iam_instance_profile" "this" {
  name = local.name
  role = aws_iam_role.instance.name
}
resource "aws_lb" "this" {
  name               = substr(local.name, 0, 32)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}
resource "aws_lb_target_group" "app" {
  name     = substr("${local.name}-app", 0, 32)
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
  health_check {
    path = "/health"
  }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = local.https_enabled ? "redirect" : "forward"
    target_group_arn = local.https_enabled ? null : aws_lb_target_group.app.arn

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = local.https_enabled ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecr_repository" "app" {
  name                 = local.name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}
resource "aws_launch_template" "app" {
  name_prefix   = "${local.name}-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  network_interfaces {
    associate_public_ip_address = !var.use_private_subnets
    security_groups             = [aws_security_group.app.id]
  }
  metadata_options {
    http_tokens = "required"
  }
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment         = var.environment
    region              = data.aws_region.current.name
    registry            = local.registry
    app_image           = var.app_image
    app_version         = try(element(reverse(split(":", var.app_image)), 0), "unknown")
    log_group           = aws_cloudwatch_log_group.app.name
    database_secret_arn = try(aws_secretsmanager_secret.database[0].arn, "")
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = local.name }
  }
}
resource "aws_autoscaling_group" "app" {
  name                      = local.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = local.app_subnet_ids
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 180
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  instance_refresh {
    strategy = "Rolling"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy_attachment.ecr,
    aws_iam_role_policy.application_logs,
    aws_iam_role_policy.database_secret,
  ]
}
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.name}-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60
  }
}
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = local.name
  dashboard_body = jsonencode({
    widgets = [{
      type = "metric"
      properties = {
        metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.this.arn_suffix]]
        period  = 60
        stat    = "Sum"
        region  = data.aws_region.current.name
        title   = "Request volume"
      }
    }]
  })
}
resource "aws_cloudwatch_metric_alarm" "unhealthy" {
  alarm_name          = "${local.name}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_actions       = var.alarm_email == null ? [] : [aws_sns_topic.alerts[0].arn]
  ok_actions          = var.alarm_email == null ? [] : [aws_sns_topic.alerts[0].arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.app.arn_suffix
    LoadBalancer = aws_lb.this.arn_suffix
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/cloudpulse/${var.environment}/application"
  retention_in_days = var.environment == "prod" ? 30 : 7
}

resource "aws_sns_topic" "alerts" {
  count = var.alarm_email == null ? 0 : 1
  name  = "${local.name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email == null ? 0 : 1
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_wafv2_web_acl" "this" {
  count = var.enable_waf ? 1 : 0
  name  = local.name
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name}-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.name
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.enable_waf ? 1 : 0
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this[0].arn
}

resource "aws_security_group" "database" {
  count  = var.enable_database ? 1 : 0
  name   = "${local.name}-database"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_db_subnet_group" "this" {
  count      = var.enable_database ? 1 : 0
  name       = local.name
  subnet_ids = aws_subnet.private[*].id
}

resource "random_password" "database" {
  count            = var.enable_database ? 1 : 0
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "database" {
  count                   = var.enable_database ? 1 : 0
  name                    = "${local.name}/database"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
}

resource "aws_db_instance" "this" {
  count                        = var.enable_database ? 1 : 0
  identifier                   = local.name
  engine                       = "postgres"
  engine_version               = "16"
  instance_class               = var.database_instance_class
  allocated_storage            = 20
  max_allocated_storage        = 100
  storage_encrypted            = true
  username                     = "cloudpulse"
  password                     = random_password.database[0].result
  db_subnet_group_name         = aws_db_subnet_group.this[0].name
  vpc_security_group_ids       = [aws_security_group.database[0].id]
  multi_az                     = var.database_multi_az
  backup_retention_period      = var.environment == "prod" ? 7 : 1
  deletion_protection          = var.environment == "prod"
  skip_final_snapshot          = var.environment != "prod"
  final_snapshot_identifier    = var.environment == "prod" ? "${local.name}-final" : null
  auto_minor_version_upgrade   = true
  performance_insights_enabled = var.environment == "prod"
}

resource "aws_secretsmanager_secret_version" "database" {
  count     = var.enable_database ? 1 : 0
  secret_id = aws_secretsmanager_secret.database[0].id
  secret_string = jsonencode({
    username = aws_db_instance.this[0].username
    password = random_password.database[0].result
    host     = aws_db_instance.this[0].address
    port     = aws_db_instance.this[0].port
    dbname   = "postgres"
  })
}

resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
}

resource "aws_budgets_budget" "monthly" {
  count        = var.monthly_budget_gbp == null ? 0 : 1
  name         = "${local.name}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_gbp)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = var.alarm_email == null ? [] : [1]
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = 80
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = [var.alarm_email]
    }
  }
}
