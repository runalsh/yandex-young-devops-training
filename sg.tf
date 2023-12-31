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
  ingress {
    #cidr_blocks = ["0.0.0.0/0"] # TEMPORARY! TODO 
    cidr_blocks = [aws_vpc.vpc_main.cidr_block]
    # cidr_blocks = ["${aws_instance.lbhttp3.private_ip}/32"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
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