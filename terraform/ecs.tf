resource "aws_cloudwatch_log_group" "cw_group1" {
  name = "mythicalmysfits-logs"
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_ecs_cluster" "cluster1" {
  name = "MythicalMysfits-Cluster"
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_ecs_task_definition" "ecs_task1" {
  family                = "mythicalmysfitsservice"
  cpu = "256"
  memory = "512"
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  execution_role_arn = aws_iam_role.ecs_service.arn
  task_role_arn = aws_iam_role.ecs_task.arn
  depends_on = [
    aws_ecr_repository.ecr_repo
  ]
  container_definitions = <<-TASK
  [
    {
      "name": "MythicalMysfits-Service",
      "image": "${aws_ecr_repository.ecr_repo.repository_url}:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "http"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.cw_group1.name}",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "awslogs-mythicalmysfits-service"
        }
      },
      "essential": true
    }
  ]
  TASK
  tags = {
    Project = "MythicalMysfits"
  }
}
#aws elbv2 create-load-balancer --name mysfits-nlb --scheme internet-facing --type network --subnets REPLACE_ME_PUBLIC_SUBNET_ONE REPLACE_ME_PUBLIC_SUBNET_TWO > ~/environment/nlb-output.json
resource "aws_lb" "ecs_nlb" {
  name               = "mysfits-nlb"
  load_balancer_type = "network"
  internal           = false
  subnets = [
    aws_subnet.pub1.id,
    aws_subnet.pub2.id
  ]
  tags = {
    Project = "MythicalMysfits"
  }
}
#aws elbv2 create-target-group --name MythicalMysfits-TargetGroup --port 8080 --protocol TCP --target-type ip --vpc-id REPLACE_ME_VPC_ID --health-check-interval-seconds 10 --health-check-path / --health-check-protocol HTTP --healthy-threshold-count 3 --unhealthy-threshold-count 3 > ~/environment/target-group-output.json
resource "aws_lb_target_group" "ecs_nlb_tg1" {
  name        = "MythicalMysfits-TargetGroup"
  target_type = "ip"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = aws_vpc.net10.id
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    Project = "MythicalMysfits"
  }
}
#aws elbv2 create-listener --default-actions TargetGroupArn=REPLACE_ME_NLB_TARGET_GROUP_ARN,Type=forward --load-balancer-arn REPLACE_ME_NLB_ARN --port 80 --protocol TCP
resource "aws_lb_listener" "ecs_nlb_lstnr1" {
  load_balancer_arn = aws_lb.ecs_nlb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_nlb_tg1.arn
  }
  tags = {
    Project = "MythicalMysfits"
  }
}
resource "aws_ecs_service" "ecs_srv1" {
  name                               = "MythicalMysfits-Service"
  cluster                            = aws_ecs_cluster.cluster1.id
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1
  task_definition                    = aws_ecs_task_definition.ecs_task1.id
  load_balancer {
    container_name   = "MythicalMysfits-Service"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.ecs_nlb_tg1.arn
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.app_sg.id]
    subnets = [
      aws_subnet.priv1.id,
      aws_subnet.priv2.id
    ]
  }
  tags = {
    Project = "MythicalMysfits"
  }
}
output "ecs_nlb_url" {
  value = aws_lb.ecs_nlb.dns_name
}