locals {
  web_asg_name = format("%s-asg", var.resource_prefix)
}

data "template_file" "ec2_web_userdata" {
  template = file("${path.module}/web.userdata")
  vars = {
    ssm_web_server_configs = format("%s-web-server-config", var.resource_prefix)
  }
}

data "aws_ami" "custom_iis_ami" {
  most_recent = "true"
  owners      = ["801119661308"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-2021.09.15"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ec2_sec_group" {
  name   = format("%s-ec2-sec-group", var.resource_prefix)
  vpc_id = module.main.vpc_id
  description = "WebServer Security Group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.main.vpc_cidr]
    description = "Allow outbound from webserver"
  }

  ingress {
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sec_group.id]
    description = "Allow RDP from bastion host"
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_servers_alb_sg.id]
    description = "Allow HTTP connection from ALB"
  }

  tags = merge(
    {
      "Name" = format("%s-ec2-sec-group", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_iam_role" "ec2_domain_join" {
  name = format("%s-ec2-domain-join-role", var.resource_prefix)

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  tags = merge(
    {
      "Name" = format("%s-ec2-domain-join-role", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "ec2_domain_join" {
  name = format("%s-ec2-domain-join-policy", var.resource_prefix)
  role = aws_iam_role.ec2_domain_join.id
  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : aws_iam_role.web_server_config.arn
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeNetworkInterfaces",
          "ec2:AttachNetworkInterface"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets"
        ],
        "Resource" : [
          aws_secretsmanager_secret_version.mad_master_password.arn
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = format("%s-ec2-ssm-instance-profile", var.resource_prefix)
  role = aws_iam_role.ec2_domain_join.name
  tags = merge(
    {
      "Name" = format("%s-ec2-ssm-instance-profile", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_launch_template" "ec2_launch_template" {
  name                   = format("%s-ec2-launch-template", var.resource_prefix)
  update_default_version = true
  key_name               = var.ec2_key_pair_name
  instance_type          = var.web_instance_type
  vpc_security_group_ids = [aws_security_group.ec2_sec_group.id]
  image_id               = data.aws_ami.custom_iis_ami.id
  user_data              = base64encode(data.template_file.ec2_web_userdata.rendered)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  }
  tags = merge(
    {
      "Name" = format("%s-ec2-launch-template", var.resource_prefix)
    },
    var.tags
  )
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "sample-web-server"
    }
  }
}

resource "aws_cloudwatch_event_rule" "web_instance_creation" {
  name = format("%s-web-instance-creation", var.resource_prefix)
  event_pattern = jsonencode({
    "source" : [
      "aws.autoscaling"
    ],
    "detail-type" : [
      "EC2 Instance-launch Lifecycle Action"
    ],
    "detail" : {
      "AutoScalingGroupName" : [
        local.web_asg_name
      ]
    }
  })
}

resource "aws_lb_target_group" "web_servers_auto_scale" {
  name                 = format("%s-ec2-target-group", var.resource_prefix)
  port                 = 80
  deregistration_delay = 10
  protocol             = "HTTP"
  vpc_id               = module.main.vpc_id
  health_check {
    port                = 80
    protocol            = "HTTP"
    matcher             = 200
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = merge(
    {
      "Name" = format("%s-ec2-target-group", var.resource_prefix)
    },
    var.tags
  )
}

resource "aws_autoscaling_group" "ec2_asg" {
  depends_on = [
    aws_cloudwatch_event_rule.web_instance_creation,
    aws_fsx_windows_file_system.fsx,
    aws_route53_resolver_rule_association.r53_mad_endpoint_fwd_rule,
    aws_ssm_document.ssm_web_server_config
  ]
  name                = local.web_asg_name
  desired_capacity    = 1
  max_size            = 1
  min_size            = 0
  vpc_zone_identifier = [module.main.web_private_subnet_ids[0]]
  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.web_servers_auto_scale.arn]

  health_check_type         = "EC2"
  health_check_grace_period = 120
  wait_for_capacity_timeout = "40m"
  tags = merge(
    {
      "Name" = format("%s-ec2-asg", var.resource_prefix)
    },
    var.tags
  )
}

# resource "aws_lb" "web_servers_alb" {
#   name                       = format("%s-web-alb", var.resource_prefix)
#   internal                   = true
#   load_balancer_type         = "application"
#   security_groups            = [aws_security_group.web_servers_alb_sg.id]
#   subnets                    = module.main.web_private_subnet_ids
#   enable_deletion_protection = false
#   drop_invalid_header_fields = true
#   tags = {
#     "Name" = format("%s-web-alb", var.resource_prefix)
#   }

# }

resource "aws_security_group" "web_servers_alb_sg" {
  name        = format("%s-web-alb-sg", var.resource_prefix)
  description = format("Security Group for %s Web ALB", var.resource_prefix)
  vpc_id      = module.main.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.main.vpc_cidr]
    description = "Allow inbound HTTP connections from VPC"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.main.vpc_cidr]
    description = "Allow outbound HTTP connections from VPC"
  }

  tags = {
    "Name" = format("%s-web-alb-sg", var.resource_prefix)
  }
}

resource "aws_lb_listener" "web_servers_alb_listener_80" {
  load_balancer_arn = aws_lb.web_servers_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers_auto_scale.arn
  }
}