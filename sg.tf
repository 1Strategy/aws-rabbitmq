resource "aws_security_group" "rabbit_lb_sg" {
  vpc_id = "${var.vpc}"

  ingress {
    from_port   = 5671
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    Name = "BIDS VXP RabbitMQ load balancer"
    Project-ID = "${var.project_id}"
    Team = "${var.team}"
  }
}

# See https://www.rabbitmq.com/ec2.html for ports to open
resource "aws_security_group" "rabbit_nodes_sg" {
  vpc_id = "${var.vpc}"

  tags {
    Name = "BIDS VXP RabbitMQ nodes"
    Project-ID = "${var.project_id}"
    Team = "${var.team}"
  }
}

resource "aws_security_group_rule" "ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.rabbit_nodes_sg.id}"

}

resource "aws_security_group_rule" "epmd_peer_discovery" {
  type = "ingress"
  from_port = 4369
  to_port = 4369
  protocol = "tcp"
  security_group_id = "${aws_security_group.rabbit_nodes_sg.id}"
  source_security_group_id = "${aws_security_group.rabbit_nodes_sg.id}"
}

resource "aws_security_group_rule" "rabbitmq_distribution_port" {
  type = "ingress"
  from_port = 25672
  to_port = 25672
  protocol = "tcp"
  security_group_id = "${aws_security_group.rabbit_nodes_sg.id}"
  source_security_group_id = "${aws_security_group.rabbit_nodes_sg.id}"
}


resource "aws_security_group_rule" "rabbitmq_alb_forwarding_port" {
  type = "ingress"
  from_port = 5671
  to_port = 5672
  protocol = "tcp"
  security_group_id = "${aws_security_group.rabbit_nodes_sg.id}"
  source_security_group_id = "${aws_security_group.rabbit_lb_sg.id}"
}

resource "aws_security_group_rule" "allow_all" {
  type = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "all"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.rabbit_nodes_sg.id}"
}