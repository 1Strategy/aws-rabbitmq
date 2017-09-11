data "aws_ami" "ubuntu" {
  owners = ["099720109477"]
  most_recent = true

  filter {
      name = "architecture"
      values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server*"]
  }
}

resource "aws_launch_configuration" "rabbit_lc" {
  name_prefix = "rbtmq-"
  associate_public_ip_address = false
  enable_monitoring = false
  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${var.ec2_keypair}"
  security_groups = ["${aws_security_group.rabbit_nodes_sg.id}"]

  user_data = "${file("userdata.sh")}"
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 5
    volume_type = "gp2"
    delete_on_termination = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "rabbit_asg" {
  name_prefix = "rbtmq-"
  launch_configuration = "${aws_launch_configuration.rabbit_lc.name}"
  min_size             = 1
  max_size             = 1
  vpc_zone_identifier = "${var.lb_subnets}"
  load_balancers    = ["${aws_elb.rabbit_elb.id}"]

tags = [
    {
      key                 = "Name"
      value               = "BIDS VXP RabbitMQ node"
      propagate_at_launch = true
    },
    {
      key                 = "Project-ID"
      value               = "${var.project_id}"
      propagate_at_launch = true
    },
    {
      key                 = "Team"
      value               = "${var.team}"
      propagate_at_launch = true
    },
]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "rabbit_elb" {
  name_prefix = "rbtmq-"
  subnets         = ["${var.lb_subnets}"]
  security_groups = ["${aws_security_group.rabbit_lb_sg.id}"]
  internal        = false

  # access_logs {
  #   bucket        = "foo"
  #   bucket_prefix = "bar"
  #   interval      = 60
  # }

  listener {
    instance_port     = 5672
    instance_protocol = "tcp"
    lb_port           = 5672
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:5672"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

    tags {
    Name = "BIDS VXP RabbitMQ load balancer"
    Project-ID = "${var.project_id}"
    Team = "${var.team}"
  }
}
