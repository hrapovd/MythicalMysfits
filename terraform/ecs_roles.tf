data "aws_caller_identity" "current" {}

#variable "account" {
#  default = data.aws_caller_identity.current.account_id
#}

resource "aws_security_group" "app_sg" {
  description = "Access to the fargate containers from the Internet"
  name        = "FargateContainerSecurityGroup"
  ingress {
    cidr_blocks = [var.vpc_cidr.vpc]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_iam_role" "ecs_service" {
  name               = "EcsServiceRole"
  path               = "/"
  assume_role_policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_iam_role_policy" "ecs_service_policy" {
  name   = "ecs_policy"
  role   = aws_iam_role.ecs_service.id
  policy = <<-POLICY1
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
          "ec2:DeleteNetworkInterfacePermission",
          "ec2:Describe*",
          "ec2:DetachNetworkInterface",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:RegisterTargets",
          "iam:PassRole",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:DescribeLogStreams",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      }
    ]
  }
  POLICY1
}

resource "aws_iam_role" "ecs_task" {
  name               = "ECSTaskRole"
  path               = "/"
  assume_role_policy = <<-POLICY2
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": ["ecs-tasks.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY2
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name   = "AmazonECSTaskRolePolicy"
  role   = aws_iam_role.ecs_task.id
  policy = <<-POLICY3
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ],
        "Resource": "arn:aws:dynamodb:*:*:table/MysfitsTable*"
      }
    ]
  }
  POLICY3
}

resource "aws_iam_role" "code_pipeline" {
  name               = "MythicalMysfitsServiceCodePipelineServiceRole"
  path               = "/"
  assume_role_policy = <<-POLICY4
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": ["codepipeline.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY4
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_iam_role_policy" "code_pipeline_policy" {
  name   = "MythicalMysfitsService-codepipeline-service-policy"
  role   = aws_iam_role.code_pipeline.id
  policy = <<-POLICY5
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject"
        ],
        "Resource": ["arn:aws:s3:::*"]
      },
      {
        "Effect": "Allow",
        "Action": [
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "ecs:*",
          "codebuild:*",
          "iam:PassRole"
        ],
        "Resource": "*"
      }
    ]
  }
  POLICY5
}

resource "aws_iam_role" "code_build" {
  name               = "MythicalMysfitsServiceCodeBuildServiceRole"
  path               = "/"
  assume_role_policy = <<-POLICY6
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": ["codebuild.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY6
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_iam_role_policy" "code_build_policy" {
  name   = "MythicalMysfitsService-CodeBuildServicePolicy"
  role   = aws_iam_role.code_build.id
  policy = <<-POLICY7
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "codecommit:ListBranches",
          "codecommit:ListRepositories",
          "codecommit:BatchGetRepositories",
          "codecommit:Get*",
          "codecommit:GitPull"
        ],
        "Resource": "arn:aws:codecommit:${var.region}:${data.aws_caller_identity.current.account_id}:MythicalMysfitsServiceRepository"
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecr:InitiateLayerUpload",
          "ecr:GetAuthorizationToken"
        ],
        "Resource": "*"
      }
    ]
  }
  POLICY7
}
