resource "null_resource" "test1" {
  provisioner "local-exec" {
    command = <<-EOF
    docker build ../aws-modern-application-workshop/module-2/app/ \
    -t ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/mythicalmysfits/service:latest
    EOF
  }
}
