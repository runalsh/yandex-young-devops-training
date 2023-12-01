#=========================== S53

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