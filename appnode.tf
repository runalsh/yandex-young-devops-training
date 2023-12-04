# #==============================LAUNCH APPPPPPP ==============================

resource "aws_launch_configuration" "launcher" {
  name_prefix   = "${var.prefix}-launcher-ec2"
  associate_public_ip_address = false
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
