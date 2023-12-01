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