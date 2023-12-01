




# resource "random_string" "randomizer" {
#   length  = 16
#   special = false
# }



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

#============================================================================================

































