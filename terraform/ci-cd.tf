resource "aws_codecommit_repository" "ci_cd_repo" {
  repository_name = "MythicalMysfitsService-Repository"
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_codebuild_project" "ci_cd_pro" {
  name = "MythicalMysfitsServiceCodeBuildProject"
  service_role = aws_iam_role.code_build.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/python:3.5.2"
    type = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name = "AWS_DEFAULT_REGION"
      value = var.region
    }
    environment_variable {
      name = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
  }
  source {
    type = "CODECOMMIT"
    location = "https://git-codecommit.${var.region}.amazonaws.com/v1/repos/${aws_codecommit_repository.ci_cd_repo.repository_name}"
  }
  tags = {
    Project = "MythicalMysfits"
  }
}
resource "aws_codepipeline" "ci_cd_pipe" {
  name = "MythicalMysfitsServiceCICDPipeline"
  role_arn = aws_iam_role.code_pipeline.arn
  artifact_store {
    location = aws_s3_bucket.ci_cd_bucket.bucket
    type = "S3"
  }
  stage {
    name = "Source"
    action {
      category = "Source"
      name = "Source"
      owner = "AWS"
      provider = "CodeCommit"
      version = "1"
      output_artifacts = ["MythicalMysfitsService-SourceArtifact"]
      configuration = {
        BranchName = "master"
        RepositoryName = "${aws_codecommit_repository.ci_cd_repo.repository_name}"
      }
      run_order = 1
    }
  }
  stage {
    name = "Build"
    action {
      category = "Build"
      name = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      output_artifacts = ["MythicalMysfitsService-BuildArtifact"]
      input_artifacts = ["MythicalMysfitsService-SourceArtifact"]
      configuration = {
        ProjectName = "${aws_codebuild_project.ci_cd_pro.name}"
      }
      run_order = 1
    }
  }
  stage {
    name = "Deploy"
    action {
      category = "Deploy"
      name = "Deploy"
      owner = "AWS"
      provider = "ECS"
      version = "1"
      input_artifacts = ["MythicalMysfitsService-BuildArtifact"]
      configuration = {
        ClusterName = "${aws_ecs_cluster.cluster1.name}"
        ServiceName = "${aws_ecs_service.ecs_srv1.name}"
        FileName = "imagedefinitions.json"
      }
    }
  }
  tags = {
    Project = "MythicalMysfits"
  }
}