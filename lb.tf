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
    path                = "/"
    port                = "80"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 2
    interval            = 3
    matcher             = "200"
  }
}

resource "aws_lb_listener" "lb-listener-80" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loadbalancer_tg.arn
  }
}

resource "aws_lb_listener" "lb-listener-443" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "${aws_acm_certificate.cert.arn}"

  default_action {
    target_group_arn = aws_lb_target_group.loadbalancer_tg.arn
    type             = "forward"
  }
}

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
    provisioner "local-exec" {   #костыльные костыли
    command = <<-EOF
      $(echo "$(aws autoscaling describe-auto-scaling-instances --region ${var.region} --output text \
      --query "AutoScalingInstances[?AutoScalingGroupName=='${aws_autoscaling_group.autoscale_group.name}'].InstanceId" \
      | xargs -n1 aws ec2 describe-instances --instance-ids $ID --region ${var.region} \
      --query "Reservations[].Instances[].PrivateIpAddress" --output text)") > asgprivateiplist.txt
    EOF
    }
    provisioner "file" {
      source      = "asgprivateiplist.txt"
      destination = "/tmp/deploy/asgprivateiplist"
      connection {
        type        = "ssh"
        host = "${aws_instance.lbhttp3.public_ip}"
        user = "admin"
        private_key = tls_private_key.example.private_key_pem
      }
    }    
    lifecycle {
    create_before_destroy = false
    }

    tags = { 
        Name = "${var.prefix}-load-balancer" 
    }
}  

