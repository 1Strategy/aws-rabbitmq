# Copyright 2017 Zulily, LLC
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

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