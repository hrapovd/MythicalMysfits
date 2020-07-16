variable "region" {
  type    = string
  default = "eu-central-1"
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_ecr_authorization_token" "token" {
}

resource "null_resource" "test1" {
  provisioner "local-exec" {
    command = <<-EOF
    docker build ../aws-modern-application-workshop/module-2/app/ \
    -t ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/mythicalmysfits/service:latest
    EOF
  }
}

resource "aws_ecr_repository" "ecr_repo" {
  name = "mythicalmysfits/service"
  depends_on = [null_resource.test1]
  provisioner "local-exec" {
    command = <<-EOF
    aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${self.repository_url}
    docker push ${self.repository_url}:latest
    EOF
  }
}