resource "null_resource" "buil_img" {
  provisioner "local-exec" {
    command = <<-EOF
    docker build ../aws-modern-application-workshop/module-2/app/ \
    -t ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/mythicalmysfits/service:latest
    EOF
  }
}
resource "aws_ecr_repository" "ecr_repo" {
  name = "mythicalmysfits/service"
  depends_on = [null_resource.buil_img]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOF
    source ~/aws/activate
    $(aws ecr get-login --region ${var.region}| awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$9}')
    docker push ${self.repository_url}:latest
    deactivate
    EOF
  }
}
