#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

resource "aws_iam_role" "spin-prod-node" {
  name = "spin-hal-prod-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "spin-prod-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.spin-prod-node.name}"
}

resource "aws_iam_role_policy_attachment" "spin-prod-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.spin-prod-node.name}"
}

resource "aws_iam_role_policy_attachment" "spin-prod-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.spin-prod-node.name}"
}

resource "aws_iam_instance_profile" "spin-prod-node" {
  name = "spin-hal-prod"
  role = "${aws_iam_role.spin-prod-node.name}"
}

resource "aws_security_group" "spin-prod-node" {
  name        = "spin-hal-prod-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.spin-prod.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "spin-hal-prod-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "spin-prod-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.spin-prod-node.id}"
  source_security_group_id = "${aws_security_group.spin-prod-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "spin-prod-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.spin-prod-node.id}"
  source_security_group_id = "${aws_security_group.spin-prod-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "spin-prod-node-ingress-workstation-tcp" {
  cidr_blocks       = ["${local.workstation-external-cidr}"]
  description       = "Allow workstation to communicate with the nodes"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.spin-prod-node.id}"
  to_port           = 10000
  type              = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  prod-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.spin-prod.endpoint}' --b64-cluster-ca '${aws_eks_cluster.spin-prod.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "spin-prod" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.spin-prod-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m5.2xlarge"
  name_prefix                 = "spin-hal-prod"
  security_groups             = ["${aws_security_group.spin-prod-node.id}"]
  user_data_base64            = "${base64encode(local.prod-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = "100"
  }
}

resource "aws_autoscaling_group" "spin-prod" {
  desired_capacity     = 3
  launch_configuration = "${aws_launch_configuration.spin-prod.id}"
  max_size             = 3
  min_size             = 1
  name                 = "spin-hal-prod"
  vpc_zone_identifier  = ["${aws_subnet.spin-prod.*.id}"]

  tag {
    key                 = "Name"
    value               = "spin-hal-prod"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
