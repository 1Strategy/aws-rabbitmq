# Copyright 2017 Zulily, LLC
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

variable "vpc" {
  type = "string"
  description = "Create RabbitMQ servers in this AWS VPC"
}

variable "lb_subnets" {
    type = "list"
    description = "RabbitMQ load balancer will be placed into these subnets."
}

variable "ec2_keypair" {
    type = "string"
    description = "Access RabbitMQ nodes via SSH with this AWS EC2 keypair name."
}

variable "project_id" {
    type = "string"
    description = "Zulily Project-ID for cost allocation"
}

variable "team" {
    type = "string"
    description = "Zulily team"
}

variable "ebs_disk_size" {
    type = "string"
    description = "EBS volume size (in GB) that is attached to the RabbitMQ node."
}
variable "instance_type" {
    type = "string"
    description = "Instance size of the RabbitMQ nodes. (i.e. t2.micro)"
}
variable "asg_min" {
    type = "string"
    description = "Minimum number of nodes in the Auto-Scaling Group"
}
variable "asg_max" {
    type = "string"
    description = "Minimum number of nodes in the Auto-Scaling Group"
}

variable "elb_name_tag" {
    type = "string"
    description = "ELB Tagged name value "
}

variable "elb_log_s3bucket_name_tag" {
    type = "string"
    description = "Tagged name value for S3 Bucket that stores ELB logs "
}

variable "asg_name_tag" {
    type = "string"
    description = "ASG Tagged name value "
}