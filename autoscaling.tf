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
  associate_public_ip_address = false
  enable_monitoring = false
  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "dougireton"
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
  launch_configuration = "${aws_launch_configuration.rabbit_lc.name}"
  min_size             = 1
  max_size             = 1
  vpc_zone_identifier = ["subnet-ef60aba6", "subnet-ef60aba6"]

  tag {
    key                 = "Name"
    value               = "chef-elb-resource-test"
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = "Ireton"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_alb" "rabbit_alb" {
#   name            = "test-alb-tf"
#   internal        = false
#   security_groups = ["${aws_security_group.alb_sg.id}"]
#   subnets         = ["${aws_subnet.public.*.id}"]

#   enable_deletion_protection = true

#   access_logs {
#     bucket = "${aws_s3_bucket.alb_logs.bucket}"
#     prefix = "test-alb"
#   }

#   tags {
#     Environment = "production"
#   }
# }