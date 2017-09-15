# Copyright 2017 Zulily, LLC
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


resource "aws_security_group" "rabbit_lb_sg" {
  vpc_id = "${var.vpc}"

  ingress {
    from_port   = 5671
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group_rule" "rabbitmq_lb_forwarding_port" {
  type = "ingress"
  from_port = 5671
  to_port = 5672
  protocol = "tcp"
  security_group_id = "${aws_security_group.rabbit_nodes_sg.id}"
  source_security_group_id = "${aws_security_group.rabbit_lb_sg.id}"
}

resource "aws_security_group_rule" "rabbitmq_mgmt_plugin" {
  type = "ingress"
  from_port = 15672
  to_port = 15672
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