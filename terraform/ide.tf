variable "ide_name" {
  type = string
  default = "MythicalMysfits"
}

variable "ide_instance_type" {
  type = string
  default = "t2.micro"
}

resource "aws_cloud9_environment_ec2" "ide1" {
  instance_type = var.ide_instance_type
  name = var.ide_name
  automatic_stop_time_minutes = 30
}