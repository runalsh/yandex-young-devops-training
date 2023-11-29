#====VARS ========================
variable "region" {
  default = "eu-central-1"
  type    = string
}

variable "prefix" {
  type    = string
}

variable "studentemail" {
  type    = string
}

variable "db_instance_type" {
  type    = string
}

variable "db_instance_name" {
   type    = string
}

variable "lb_instance_type" {
  type    = string
}

variable "mon_instance_type" {
  type    = string
}

variable "database_ip_internal" {
   type    = string
}

variable "dbpassword" {
  type    = string
}
variable "dbname" {
  type    = string
}
variable "dbuser" {
  type    = string
}

variable "domain" {
  type    = string
}

variable "app_instance_type" {
  type    = string
}
variable "app_si_instance_type" {
  type    = string
}
variable "app_si_instances" {
  type    = string
}
variable "app_si_ip_internal" {
  type    = string
}

variable "app_desired_intsances" {
  type    = string
}
variable "app_minimum_instances" {
  type    = string
}
variable "app_maximum_instances" {
  type    = string
}

variable "db_ec2instance_type" {
  type    = string
}

variable "public_subnets" {
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

data "aws_ami" "debian" {
  most_recent = true
  owners = ["136693071363"]
  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#====KEY ========================
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

variable "key_name" {
  type    = string
  default = "universalnew"
}

#=============cloud-init===============================================================

data "template_file" "dbinit" {
  template = file("./dbinit.yml")
  vars = {
    #dbinternalip = "${var.database_ip_internal}"
    #dbinternalipfromaws = "${aws_instance.db.private_ip}"
    dbname = "${var.dbname}"
    dbuser = "${var.dbuser}"
    dbpassword = "${var.dbpassword}"
    studentemail = "${var.studentemail}"
    vpccidrblock = "${aws_vpc.vpc_main.cidr_block}"
  }
}  

data "template_cloudinit_config" "dbinit_config" {
  gzip          = false
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = data.template_file.dbinit.rendered
  }
}

data "template_file" "http3loadbalancer" {
  template = file("./http3loadbalancer.yml")
  vars = {
    http3loadbalanceradress = "${aws_route53_record.load_balancer_record.name}"
    # asgprivateip = ["${element(data.aws_autoscaling_group.getprivateips.private_ips, var.app_desired_intsances)}"]
  }
}

data "template_cloudinit_config" "http3loadbalancer" {
  gzip          = false
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = data.template_file.http3loadbalancer.rendered
  }
}

data "archive_file" "http3loadbalancer" {
  type = "zip"
  source_dir  = "configs"
  output_path = "${path.module}/configs.zip"
}

data "template_file" "bingoinit" {
  template = file("./bingoci.yml")
  vars = {
    #dbinternalip = "${var.database_ip_internal}"
    dbinternalipfromaws = "${aws_instance.db.private_ip}"
    dbname = "${var.dbname}"
    dbuser = "${var.dbuser}"
    dbpassword = "${var.dbpassword}"
    studentemail = "${var.studentemail}"
  }
}

data "template_cloudinit_config" "bingo_config" {
  gzip          = false
  base64_encode = true
  part {
    filename     = "./bingoci.yml"
    content_type = "text/cloud-config"
    content      = data.template_file.bingoinit.rendered
  }
}

#========== S3 ======================================================================================

# resource "aws_s3_bucket" "terraform_state" {
#    bucket = "statebucket"
#    lifecycle {
#      prevent_destroy = true
#    }
#     versioning {
#       enabled = true
#     }
#  } 

# terraform {
#   backend "s3" {
#     bucket = "statebucket"
#     key    = "statebucket/terraform.tfstate"
#     region = "eu-central-1"
#   }
# }

resource "aws_s3_bucket" "lblogs" {
  bucket        = "logsfromelb"
  force_destroy = true
}



#==== provider ======================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.26.0"
    }
  }
}

provider "aws" {
  region = var.region
}

#==== policy ======================

resource "aws_iam_instance_profile" "ecs_service_role" {
  role = aws_iam_role.ecs-instance-role.name
}


resource "aws_iam_role" "ecs-instance-role" {
  name = "ecs-instance-role"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
  role       = aws_iam_role.ecs-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


resource "aws_s3_bucket_policy" "lblogs" {
  bucket = aws_s3_bucket.lblogs.id
  policy = data.aws_iam_policy_document.lblogs.json
}

data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "lblogs" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.lblogs.arn,
      "${aws_s3_bucket.lblogs.arn}/*",
    ]
  }
}

# resource "aws_iam_role" "awsserviceroleforautoscaling" {
#   name               = "awsserviceroleforautoscaling"
#   path = "/"
#   assume_role_policy = <<EOF
# {
#   "Version": "2008-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": ["ec2.amazonaws.com"]
#       },
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }

#=================== SG=================================================

resource "aws_security_group" "sg_main" {
  name   = "${var.prefix}-aws-sec-group-main"
  #description = "allowed 22 80 443"
  description = "14558"
  vpc_id = aws_vpc.vpc_main.id 
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  ingress {
    #cidr_blocks = ["0.0.0.0/0"] # TEMPORARY! TODO 
    cidr_blocks = [aws_vpc.vpc_main.cidr_block]
    #cidr_blocks = ["${aws_instance.lbhttp3.private_ip}/32"]
    from_port         = 8
    to_port           = 0
    protocol          = "icmp"
    description       = "Allow ping"
  }
  # ingress {
  #   #cidr_blocks = ["0.0.0.0/0"] # TEMPORARY! TODO 
  #   #cidr_blocks = [aws_vpc.vpc_main.cidr_block]
  #   cidr_blocks = ["${aws_instance.lbhttp3.private_ip}/32"]
  #   from_port   = 80
  #   protocol    = "tcp"
  #   to_port     = 80
  # }
  # ingress {
  #   #cidr_blocks = ["0.0.0.0/0"]
  #   #cidr_blocks = [aws_vpc.vpc_main.cidr_block]
  #   cidr_blocks = ["${aws_instance.lbhttp3.private_ip}/32"]
  #   from_port   = 443
  #   protocol    = "tcp"
  #   to_port     = 443
  # }
  ingress {
    #cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = [aws_vpc.vpc_main.cidr_block]
    #cidr_blocks = ["${aws_instance.lbhttp3.private_ip}/32"]
    from_port   = 14558
    protocol    = "tcp"
    to_port     = 14558
  }  
  # #  ingress {
  #   cidr_blocks = ["0.0.0.0/0"] # TEMPORARY! TODO 
  #   #cidr_blocks = [aws_vpc.vpc_main.cidr_block]
  #     #cidr_blocks = ["${aws_instance.lbhttp3.private_ip}/32"]
  #   from_port   = 22
  #   protocol    = "tcp"
  #   to_port     = 22
  # }
  # ingress {
  #   from_port = 0
  #   to_port = 65535
  #   protocol = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"] # TEMPORARY! TODO 
  #   #cidr_blocks = [aws_vpc.vpc_main.cidr_block]
  #  }    
  # ingress {
  #   from_port = 0
  #   to_port = 65535
  #   protocol = "udp"
  #   cidr_blocks = ["0.0.0.0/0"]    # TEMPORARY! TODO TODO remove completely
  #   #cidr_blocks = [aws_vpc.vpc_main.cidr_block]
  # }
}

resource "aws_security_group" "lb" {
  name   = "${var.prefix}-aws-lb-sec-group-main"
  description = "allowed 22 80 443"
  vpc_id = aws_vpc.vpc_main.id 
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"] # TEMPORARY! TODO 
    #cidr_blocks = [aws_vpc.vpc_main.cidr_block]
    from_port         = 8
    to_port           = 0
    protocol          = "icmp"
    description       = "Allow ping"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"] 
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }  
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "udp"
    to_port     = 443
  }
    ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
  }
}

resource "aws_security_group" "db_sg" {
  name   = "${var.prefix}-db_sg"
  vpc_id = aws_vpc.vpc_main.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"] # TEMPORARY! TODO 
    #cidr_blocks = [aws_vpc.vpc_main.cidr_block]
    from_port         = 8
    to_port           = 0
    protocol          = "icmp"
    description       = "Allow ping"
  }
  ingress {
    description      = "allow db pgbouncer"
    from_port        = 6432
    to_port          = 6432
    protocol         = "tcp"
    cidr_blocks = [aws_vpc.vpc_main.cidr_block]
    #cidr_blocks = ["0.0.0.0/0"]  # TEMPORARY! TODO 
  }
  # ingress {
  #   cidr_blocks = ["0.0.0.0/0"] # TEMPORARY! TODO 
  #   #cidr_blocks      = [aws_vpc.vpc_main.cidr_block]
  #   from_port   = 22
  #   protocol    = "tcp"
  #   to_port     = 22
  # }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    #cidr_blocks      = [aws_vpc.vpc_main.cidr_block]
    cidr_blocks =     ["0.0.0.0/0"] 
  }
  tags = {
    name = "${var.prefix}-db-sec-group"
  }
}
#===================network======================================================================

resource "aws_internet_gateway" "igw_main" {
  vpc_id = aws_vpc.vpc_main.id
  tags = {
    Name = "${var.prefix}-gateway"
  }
}

data "aws_availability_zones" "aviable_zones" {
  state                   = "available"
}

resource "aws_subnet" "subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.aviable_zones.names[count.index]
  map_public_ip_on_launch = "true"
}

resource "aws_db_subnet_group" "sub_db_sg_rds" {
  name       = "${var.prefix}-rds-subnet-db-sg"
  subnet_ids = [aws_subnet.subnets.0.id, aws_subnet.subnets.1.id]
  tags = {
    name = "${var.prefix}-rds-db-subnet-group"
  }
}

resource "aws_vpc" "vpc_main" {
  tags = {
    Name = "${var.prefix}-aws-vpc-main"
  }
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_route_table" "vpc_route" {
  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_main.id
  }
}

resource "aws_route_table_association" "vpc_route_assoc" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.vpc_route.id
}

# #==============================LAUNCH APPPPPPP ==============================

resource "aws_launch_configuration" "launcher" {
  name_prefix   = "${var.prefix}-launcher-ec2"
  associate_public_ip_address = false  ### убрать TODO
  enable_monitoring           = true
  image_id                    = data.aws_ami.debian.id
  instance_type               = var.app_instance_type
  iam_instance_profile        = aws_iam_instance_profile.ecs_service_role.arn
  key_name                    = "universal"
  security_groups              = [aws_security_group.sg_main.id]
  user_data                   = data.template_cloudinit_config.bingo_config.rendered
    lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscale_group" {
  name                      = "${var.prefix}-autoscale_group-${aws_launch_configuration.launcher.name}"
  # default_cooldown        = 300
  desired_capacity        = var.app_desired_intsances
  health_check_grace_period = 60
  target_group_arns     = [aws_lb_target_group.loadbalancer_tg.arn]
  health_check_type       = "ELB"
  launch_configuration    = aws_launch_configuration.launcher.id
  max_size                = var.app_maximum_instances
  metrics_granularity     = "1Minute"
  min_size                = var.app_minimum_instances
  vpc_zone_identifier       = aws_subnet.subnets.*.id
  force_delete              = true
  depends_on                = [aws_instance.db]
  #service_linked_role_arn = aws_iam_role.awsserviceroleforautoscaling.arn
  #protect_from_scale_in = true
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      instance_warmup        = 30
    }
  }  
  tag {
    key                 = "Description"
    propagate_at_launch = true
    value               = "ASG"
  }
   lifecycle {
    create_before_destroy = true
  }
  # provisioner "local-exec" {
  #   command = "./getipsfromasg.sh"
  # }
}
# data "autoscaling_group" "getprivateips" {
#   autoscaling_id = "${aws_autoscaling_group.autoscale_group.id}"
#   get_instance_properties = true
# }


# resource "aws_instance" "bingogoapp" {
#   count                       = var.app_si_instances
#   associate_public_ip_address = false  ### убрать TODO
#   ami                         = data.aws_ami.debian.id
#   instance_type               = var.app_si_instance_type
#   iam_instance_profile        = aws_iam_instance_profile.ecs_service_role.arn
#   key_name                    = "universal"
#   security_groups             = [aws_security_group.sg_main.id]
#   private_ip                  = "${var.app_si_ip_internal}${count.index}"
#   user_data_replace_on_change =  true 
#   user_data = data.template_cloudinit_config.bingo_config.rendered

#   lifecycle {
#     create_before_destroy = false
#   }
#   tags = {
#     Name  = "Node-${count.index}"
#   }
# }

#=================================BALANCER=========================

resource "aws_lb" "loadbalancer" {
  name                       = "${var.prefix}-load-balancer"
  load_balancer_type         = "application"
  subnets                    = aws_subnet.subnets.*.id
  security_groups            = [aws_security_group.lb.id]
  enable_deletion_protection = false
  internal                   = false
  access_logs {
    bucket  = aws_s3_bucket.lblogs.bucket
    enabled = true
  }
}

resource "aws_lb_target_group" "loadbalancer_tg" {
  name        = "${var.prefix}-load-balancer-tg"
  #port        = "80"
  port        = "14558"
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_main.id
  health_check {
    path                = "/pinglb"
    port                = "80"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}

# resource "aws_lb_listener" "lb-listener-80" {
#   load_balancer_arn = aws_lb.loadbalancer.arn
#   port              = "80"
#   protocol          = "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.loadbalancer_tg.arn
#   }
# }

# resource "aws_lb_listener" "lb-listener-443" {
#   load_balancer_arn = aws_lb.loadbalancer.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = "${aws_acm_certificate.cert.arn}"

#   default_action {
#     target_group_arn = aws_lb_target_group.loadbalancer_tg.arn
#     type             = "forward"
#   }
# }


# resource "random_string" "randomizer" {
#   length  = 16
#   special = false
# }

# ++++++++++++++++++++++++++++++++++++ CERTIFICATE SELFSIGNED +++++++++++++++++++++++++++++++++++++++++
#          надо бы переделать под домен на letsencrypt TODO

# resource "tls_private_key" "key" {
#   algorithm = "RSA"
# }

# resource "tls_self_signed_cert" "cert" {
#   # key_algorithm         = "RSA"
#   private_key_pem       = "${tls_private_key.key.private_key_pem}"
#   validity_period_hours = 87600

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]

#   dns_names = ["*.${var.region}.elb.amazonaws.com"]

#   subject {
#     common_name  = "*.${var.region}.elb.amazonaws.com"
#     organization = "ORGANIZATION"
#     province     = "STATE"
#     country      = "COUNT"
#   }
# }

# resource "tls_self_signed_cert" "public_cert" {
#   # key_algorithm         = "RSA"
#   private_key_pem       = "${tls_private_key.key.private_key_pem}"
#   validity_period_hours = 87600

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]

#   dns_names = ["*.${var.region}.elb.amazonaws.com"]

#   subject {
#     common_name  = "*.${var.region}.elb.amazonaws.com"
#     organization = "ORGANIZATION"
#     province     = "STATE"
#     country      = "COUNT"
#   }
# }

# resource "aws_acm_certificate" "cert" {
#   private_key      = "${tls_private_key.key.private_key_pem}"
#   certificate_body = "${tls_self_signed_cert.public_cert.cert_pem}"
# }

#  =========================== S53

resource "aws_route53_zone" "domain" {
  name = "${var.domain}."
}

resource "aws_iam_role_policy_attachment" "route53_modify_policy" {
  policy_arn = aws_iam_policy.route53_modify_policy.arn
  role       = aws_iam_role.ecs-instance-role.name
}

resource "aws_iam_policy" "route53_modify_policy" {
  name        = "route53_modify_policy"
  path        = "/"
  description = "This policy allows route53 modifications"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_route53_record" "load_balancer_record" {
  name    = "elb.${var.domain}"
  type    = "A"
  # ttl     = 60
  zone_id = aws_route53_zone.domain.zone_id
  alias {
    evaluate_target_health  = false
    name                    = "${aws_lb.loadbalancer.dns_name}"
    zone_id                 = "${aws_lb.loadbalancer.zone_id}"
  }
}

resource "aws_route53_record" "load_balancer_http3_record" {
  name    = "http3lb.${var.domain}"
  type    = "A"
  ttl     = "60"
  zone_id = aws_route53_zone.domain.zone_id
  records = [aws_instance.lbhttp3.public_ip]
}

#======================================================================================================
#============= didnt work because AWS wanna extra validation for domains via support :C
#======================================================================================================

# resource "aws_acm_certificate" "certformydomain" {
#   domain_name       = "lb.${var.domain}"
#   validation_method = "DNS"
# }

# resource "aws_route53_record" "cert_validation_dns_record" {
#   for_each = {
#     for dvo in aws_acm_certificate.certformydomain.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.domain.zone_id
# }

# resource "aws_acm_certificate_validation" "cert_validation" {
#   certificate_arn         = aws_acm_certificate.certformydomain.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation_dns_record : record.fqdn]
# }


#=============DB===============================================================

resource "aws_instance" "db" {
    ami                     = data.aws_ami.debian.id
    instance_type           = var.db_ec2instance_type
    subnet_id               = aws_subnet.subnets.0.id
    vpc_security_group_ids  = [aws_security_group.db_sg.id]
    key_name                = var.key_name
    iam_instance_profile    = "${aws_iam_instance_profile.ecs_service_role.name}"
    private_ip              = var.database_ip_internal
    associate_public_ip_address = false

    user_data_replace_on_change =  true
    user_data = data.template_cloudinit_config.dbinit_config.rendered
      
    lifecycle {
      create_before_destroy = false
    }
    
    tags = { 
        Name = "${var.prefix}-database-instance" 
    }
}  

# resource "aws_db_instance" "db" {
#   identifier = var.db_instance_name
#   engine = "postgres"
#   engine_version = "15.4"
#   allocated_storage = 5
#   instance_class = var.db_instance_type
#   vpc_security_group_ids = [aws_security_group.db_sg.id]
#   availability_zone = "eu-central-1a" 
#   db_subnet_group_name = aws_db_subnet_group.sub_db_sg_rds.id
#   db_name = var.dbname
#   username = var.dbuser
#   password = var.dbpassword
#   #publicly_accessible = true
#   publicly_accessible = false
#   skip_final_snapshot = true
#   tags = {
#     name = "${var.prefix}-db-postgresql"
#   }
# }
#=============monitoringr===============================================================
# resource "aws_instance" "monitoring" {
#     ami                     = data.aws_ami.debian.id
#     instance_type           = var.mon_instance_type
#     subnet_id               = aws_subnet.subnets.0.id
#     vpc_security_group_ids  = [aws_security_group.monitoring.id]
#     key_name                = var.key_name
#     iam_instance_profile    = "${aws_iam_instance_profile.ecs_service_role.name}"
#     associate_public_ip_address = true

#     user_data_replace_on_change =  true 
#     user_data = data.template_cloudinit_config.http3loadbalancer.rendered
#     provisioner "file" {
#       source      = "configs.zip"
#       destination = "/tmp/configs.zip"
#       connection {
#         type        = "ssh"
#         host = "${aws_instance.monitoring.public_ip}"
#         user = "admin"
#         private_key = tls_private_key.example.private_key_pem
#       }
#     }

#     lifecycle {
#     create_before_destroy = false
#     }

#     tags = { 
#         Name = "${var.prefix}-load-balancer" 
#     }
# }  
#============= ec2 load balancer===============================================================

resource "aws_instance" "lbhttp3" {
    ami                     = data.aws_ami.debian.id
    instance_type           = var.lb_instance_type
    subnet_id               = aws_subnet.subnets.0.id
    vpc_security_group_ids  = [aws_security_group.lb.id]
    key_name                = var.key_name
    iam_instance_profile    = "${aws_iam_instance_profile.ecs_service_role.name}"
#   private_ip              = "10.0.0.251"
    associate_public_ip_address = true

    user_data_replace_on_change =  true 
    user_data = data.template_cloudinit_config.http3loadbalancer.rendered
    provisioner "file" {
      source      = "configs.zip"
      destination = "/tmp/configs.zip"
      connection {
        type        = "ssh"
        host = "${aws_instance.lbhttp3.public_ip}"
        user = "admin"
        private_key = tls_private_key.example.private_key_pem
      }
    }
    provisioner "local-exec" {
    command = <<-EOF
      echo $(aws autoscaling describe-auto-scaling-instances --region ${var.region} --output text \
      --query "AutoScalingInstances[?AutoScalingGroupName=='${aws_autoscaling_group.autoscale_group.name}'].InstanceId" \
      | xargs -n1 aws ec2 describe-instances --instance-ids $ID --region ${var.region} \
      --query "Reservations[].Instances[].PrivateIpAddress" --output text) > /tmp/deploy/asgprivateiplist
      for i in
    EOF
  }
    lifecycle {
    create_before_destroy = false
    }

    tags = { 
        Name = "${var.prefix}-load-balancer" 
    }
}  


#============================================================================================

































