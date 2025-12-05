// Launch template using a fixed golden AMI
resource "aws_launch_template" "main" {
  name                    = "${var.env}-${var.project_name}-launch-template"
  description             = "The template of EC2 for autoscale"
  disable_api_termination = false

  image_id                             = "ami-093a7f5fbae13ff67" // <---- ami from amazon linux. regioonal to singapore
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.golden_ami_spec.instance_type
  ebs_optimized                        = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.app_sg.id]


  user_data = base64encode(templatefile("${path.module}/script/user-data.tpl",
    {
      aws_env    = var.env
      project    = var.project_name
    }
  ))

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 50
      volume_type = "gp3"
      encrypted   = true
    }
  }

  monitoring {
    enabled = true
  }

  tags = local.common_tags
}

resource "aws_autoscaling_group" "app_asg" {
  name                      = var.asg_name
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  vpc_zone_identifier = values(aws_subnet.private_subnet)[*].id
  target_group_arns = [aws_lb_target_group.app.arn]
  termination_policies = [
    "OldestLaunchTemplate",
    "OldestInstance",
    "Default"
  ]

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 120
    }

    triggers = ["launch_template"]
  }

    tag {
    key                 = "Managedby"
    value               = "Terraform"
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "app" {
  name_prefix          = "app-"
  port                 = 80
  protocol             = "HTTP"

  vpc_id = aws_vpc.resilience_architecture_vpc.id

  tags                 = local.common_tags
  deregistration_delay = 60

  health_check {
    enabled           = true
    healthy_threshold = 2
    interval          = 30
    matcher           = "200"
    path              = "/"
    port              = "traffic-port"
    protocol          = "HTTP"
    timeout           = 5
  }
}

resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    host_header {
      values = ["demo.your-domain.com"]
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

// lb
resource "aws_lb" "app_lb" {
  name               = "${var.project_name}-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = values(aws_subnet.public_subnet)[*].id
  tags               = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

//app sg
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for EC2 instances behind ALB"
  vpc_id      = aws_vpc.resilience_architecture_vpc.id

  # Allow HTTP from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Allow all outbound (for yum, CloudWatch, SSM, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.env}-${var.project_name}-app-sg"
  })
}


//sec group for lb
resource "aws_security_group" "lb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.resilience_architecture_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.env}-${var.project_name}-alb-sg"
  })
}

/// add iam role for ec2 to enable cloudwatch and ssm

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.env}-${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.env}-${var.project_name}-ec2-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
