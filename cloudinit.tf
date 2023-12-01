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




