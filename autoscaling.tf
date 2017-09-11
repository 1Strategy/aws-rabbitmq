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
  target_group_arns   = ["${aws_alb_target_group.rabbit_alb_tg.arn}"]

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

resource "aws_alb" "rabbit_alb" {
  # name            = "test-alb-tf"
  name_prefix = "rbtmq-"
  internal        = false
  security_groups = ["${aws_security_group.rabbit_lb_sg.id}"]
  subnets         = ["${var.lb_subnets}"]

  enable_deletion_protection = true

  # access_logs {
  #   bucket = "${aws_s3_bucket.alb_logs.bucket}"
  #   prefix = "test-alb"
  # }

  tags {
    Name = "BIDS VXP RabbitMQ load balancer"
    Project-ID = "${var.project_id}"
    Team = "${var.team}"
  }
}

resource "aws_alb_target_group" "rabbit_alb_tg" {
  name_prefix = "rbtmq-"
  port     = 5672
  protocol = "HTTP"
  vpc_id   = "${var.vpc}"
  
  health_check {
    interval = "30"
    path = "/"
    port = "5672"
    protocol = "HTTP"
    timeout = "5"
  }  

  tags {
    Name = "BIDS VXP RabbitMQ load balancer"
    Project-ID = "${var.project_id}"
    Team = "${var.team}"
  }
  
}

resource "aws_alb_listener" "rabbit_alb_l" {
  load_balancer_arn = "${aws_alb.rabbit_alb.arn}"
  port              = "5672"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.rabbit_alb_tg.arn}"
    type             = "forward"
  }
}
