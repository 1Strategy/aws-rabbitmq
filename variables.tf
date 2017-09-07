variable "vpc" {
  type = "string"
  description = "Create RabbitMQ servers in this AWS VPC"
}

variable "project_id" {
    type = "string"
    description = "Zulily Project-ID for cost allocation"
}

variable "team" {
    type = "string"
    description = "Zulily team"
}