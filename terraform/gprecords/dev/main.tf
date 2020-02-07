terraform {
  required_version = ">= 0.12.16"

  # Uncomment for s3 tf state support
  #backend "s3" {
  #  bucket = "api-tf-backend"
  #  key    = "terraform/gprecords-proxy/dev"
  #  region = "eu-west-2"
  #}
}

provider "aws" {
  version = "~> 2.0"
  region  = var.gateway_region
}

#This is NOT a typo, it is hack for TF/aws provider bug
provider "aws" {
  version = "~> 2.0"
  region  = var.gateway_region
  alias   = "eu-west"
}


##########################################################
##
## EC2 instance
##
##########################################################
resource "aws_instance" "gprecords_activityproxy" {
  ami           = var.ami_id_server
  instance_type = "t3.micro"

  subnet_id       = var.subnet_id
  key_name        = var.ssh_key_name
  security_groups = [aws_security_group.gprecords_activityproxy_sg.id]
  tags = {
    Name = "gprecords Proxy"
  }
  user_data            = data.template_file.user_data.rendered
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    container_name       = var.container_name
    aws_region           = data.aws_region.current.name
    docker_repo          = var.docker_repo
    docker_repo_user     = var.docker_repo_user
    docker_repo_password = var.docker_repo_password
  }
}

data "aws_region" "current" {
}


##########################################################
##
## Security group for the EC2 instance
##
##########################################################

resource "aws_security_group" "gprecords_activityproxy_sg" {
  vpc_id = var.vpc_id
  name   = "gprecords_activityproxy_sg"
}

resource "aws_security_group_rule" "gprecords_activityproxy_ssh_sgr" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "22"
  to_port           = "22"
  cidr_blocks       = var.allowed_inbound_cidr_blocks
  security_group_id = aws_security_group.gprecords_activityproxy_sg.id
}

resource "aws_security_group_rule" "gprecords_activityproxy_web_sgr" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "8080"
  to_port           = "8080"
  cidr_blocks       = var.allowed_inbound_cidr_blocks
  security_group_id = aws_security_group.gprecords_activityproxy_sg.id
}

resource "aws_security_group_rule" "gprecords_activityproxy_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gprecords_activityproxy_sg.id
}


##########################################################
##
## IAM policy/role for the EC2 instance
##
##########################################################

resource "aws_iam_instance_profile" "instance_profile" {
  name = "activityproxy_instanceprofile"
  path = "/"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name               = "activityproxy_role"
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "activityproxy_policy" {
  name   = "activityproxy_policy"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.activityproxy_policy_document.json
}

data "aws_iam_policy_document" "activityproxy_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:*",
    ]

    resources = ["*"]
  }
}

#-------ALB-------
resource "aws_security_group" "lc_security_group" {
  name_prefix = "ActivityProxyLC"
  description = "Security group for the launch configuration"
  vpc_id      = var.vpc_id

  # aws_launch_configuration.launch_configuration in this module sets create_before_destroy to true, which means
  # everything it depends on, including this resource, must set it as well, or you'll get cyclic dependency errors
  # when you try to do a terraform destroy.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "gprecords-actvityproxy-elb-sg" {
  count  = var.enable_elb ? 1 : 0
  name   = var.gprecords_elb_sg_name
  vpc_id = var.vpc_id
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.gprecords_elb_whitelist_cidr
  }
}

resource "aws_security_group_rule" "allow_http_gateway_tcp_inbound_from_alb" {
  #count                    = var.allowed_inbound_security_group_count
  #count                    = length(var.allowed_inbound_cidr_blocks) >= 1 ? 1 : 0
  count                    = var.enable_elb ? 1 : 0
  type                     = "ingress"
  from_port                = var.gateway_http_port
  to_port                  = var.gateway_http_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gprecords-actvityproxy-elb-sg[count.index].id

  security_group_id = aws_security_group.lc_security_group.id
}


resource "aws_lb" "gprecords-actvityproxy-gateway-elb" {
  count = var.enable_elb ? 1 : 0
  access_logs {
    enabled = false
    bucket  = ""
    prefix  = var.elb_access_logs_prefix
  }

  enable_deletion_protection = false
  enable_http2               = true
  idle_timeout               = "60"
  internal                   = false
  ip_address_type            = "ipv4"
  load_balancer_type         = "application"
  name                       = var.elb_name
  security_groups            = ["${aws_security_group.gprecords-actvityproxy-elb-sg[count.index].id}"]
  #security_groups            = [var.security_group_id]

  subnets = var.public_elb_subnet_ids
}


resource "aws_lb_target_group" "gprecords-actvityproxy-gateway-tg" {
  deregistration_delay = "300"

  health_check {
    enabled             = true
    healthy_threshold   = "5"
    interval            = "60"
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "30"
    unhealthy_threshold = "2"
  }

  name       = var.elb_target_group_name
  port       = var.gateway_http_port
  protocol   = "HTTP"
  slow_start = "0"

  stickiness {
    cookie_duration = "86400"
    enabled         = false
    type            = "lb_cookie"
  }


  target_type = "instance"
  vpc_id      = var.vpc_id
}


resource "aws_alb_listener" "gprecords-actvityproxy-gateway-alb_listener" {
  count             = var.enable_elb ? 1 : 0
  load_balancer_arn = aws_lb.gprecords-actvityproxy-gateway-elb[count.index].arn
  port              = var.alb_listener_port
  protocol          = var.alb_listener_protocol
  ssl_policy        = var.elb_listener_security_policy
  certificate_arn   = var.elb_certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.gprecords-actvityproxy-gateway-tg.arn
    type             = "forward"
  }
}

#------ALIAS----
resource "aws_route53_record" "gprecords-actvityproxy-gateway" {
  count   = var.enable_elb ? 1 : 0
  zone_id = var.target_domain_hosted_zone_id
  name    = var.gateway_route53_record_alias
  type    = "A"

  alias {
    name                   = aws_lb.gprecords-actvityproxy-gateway-elb[count.index].dns_name
    zone_id                = var.alias_target_elb_hosted_zone_id
    evaluate_target_health = true
  }
}
