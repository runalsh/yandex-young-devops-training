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
