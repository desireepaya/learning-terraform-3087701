data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}

module "blog_autoscaling" {
  source   = "terraform-aws-modules/autoscaling/aws"
  version  = "9.0.1"
  
  name                = "${var.environment.name}-blog"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  vpc_zone_identifier = module.blog_vpc.public_subnets
  security_groups     = [module.blog_sg.security_group_id]

  image_id      = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  traffic_source_attachments = {
    alb = {
      traffic_source_identifier = module.blog_alb.target_groups["ex-instance"].arn
    }
  }
}

module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"

  name_prefix     = "${var.environment.name}-"
  vpc_id          = module.blog_vpc.vpc_id
  subnets         = module.blog_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]

  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "${var.environment.network_prefix}.0.0/16"
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  target_groups = {
    ex-instance = {
      name_prefix       = "${var.environment.name}-"
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      vpc_id            = module.blog_vpc.vpc_id
      create_attachment = false     # <— let the ASG attach itself
    }
  }
  tags = {
    Environment = var.environment.name  }
  }


module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"
  
  name                = "${var.environment.name}-blog"
  vpc_id              = module.blog_vpc.vpc_id
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  
  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}
