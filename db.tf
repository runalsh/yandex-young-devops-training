#=============DB===============================================================

resource "aws_instance" "db" {
    ami                     = data.aws_ami.debian.id
    instance_type           = var.db_ec2instance_type
    subnet_id               = aws_subnet.subnets.0.id
    vpc_security_group_ids  = [aws_security_group.db_sg.id]
    key_name                = var.key_name
    iam_instance_profile    = "${aws_iam_instance_profile.ecs_service_role.name}"
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
