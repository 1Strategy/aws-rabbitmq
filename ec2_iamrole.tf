resource "aws_iam_role" "rabbit_node_role" {
  name = "rabbit_node_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "rabbit_p" {
  name        = "rabbit_p"
  path        = "/"
  description = "Policy to allow RabbitMQ Auto Scaling plugin to be able to identify other RabbitMQ nodes."
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "rabbit_p_to_r" {
  role       = "${aws_iam_role.rabbit_node_role.name}"
  policy_arn = "${aws_iam_policy.rabbit_p.arn}"
}