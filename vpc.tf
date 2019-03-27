#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "spin-prod" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
     "Name", "spin-hal-prod-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "spin-prod" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.spin-prod.id}"

  tags = "${
    map(
     "Name", "spin-hal-prod-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "spin-prod" {
  vpc_id = "${aws_vpc.spin-prod.id}"

  tags {
    Name = "spin-hal-prod"
  }
}

resource "aws_route_table" "spin-prod" {
  vpc_id = "${aws_vpc.spin-prod.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.spin-prod.id}"
  }
}

resource "aws_route_table_association" "spin-prod" {
  count = 2

  subnet_id      = "${aws_subnet.spin-prod.*.id[count.index]}"
  route_table_id = "${aws_route_table.spin-prod.id}"
}
