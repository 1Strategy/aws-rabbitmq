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

