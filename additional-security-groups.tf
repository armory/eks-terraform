resource "aws_security_group" "load-balancer-ingress" {
  name        = "spin-hal-prod-lb-ingress"
  description = "Communication with production LB"
  vpc_id      = "${aws_vpc.spin-prod.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  tags {
    Name = "spin-hal-prod-lb-ingress"
  }
}

resource "aws_security_group_rule" "spin-prod-cluster-lb-ingress-github-hooks" {
  cidr_blocks       = ["192.30.252.0/22", "185.199.108.0/22", "140.82.112.0/20"]
  description       = "Security group for github webhook calls"
  from_port         = 0
  protocol          = "tcp"
  security_group_id = "${aws_security_group.load-balancer-ingress.id}"
  to_port           = 65535
  type              = "ingress"
}

resource "aws_security_group_rule" "spin-prod-cluster-ingress-lb-workstation" {
  cidr_blocks       = ["${local.workstation-external-cidr}"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.load-balancer-ingress.id}"
  type              = "ingress"
}
