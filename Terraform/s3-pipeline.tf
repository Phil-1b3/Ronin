# S3 Pipeline Infrastructure for Static Website Deployment

# S3 Bucket for Pipeline artifacts (separate from website bucket)
resource "aws_s3_bucket" "s3_pipeline_artifacts" {
  bucket        = "phil-s3-pipeline-artifacts-${phil-ronin-ware-com-5elkags1}"
  force_destroy = false
}

resource "random_string" "s3_pipeline_suffix" {
  length  = 8
  special = false
  upper   = false
}

# IAM Role for S3 Pipeline
resource "aws_iam_role" "s3_pipeline_role" {
  name = "phil-s3-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_pipeline_policy" {
  name = "phil-s3-pipeline-policy"
  role = aws_iam_role.s3_pipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.s3_pipeline_artifacts.arn,
          "${aws_s3_bucket.s3_pipeline_artifacts.arn}/*",
          aws_s3_bucket.phil_website.arn,
          "${aws_s3_bucket.phil_website.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for S3 Build
resource "aws_iam_role" "s3_build_role" {
  name = "phil-s3-build-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_build_policy" {
  name = "phil-s3-build-policy"
  role = aws_iam_role.s3_build_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.s3_pipeline_artifacts.arn,
          "${aws_s3_bucket.s3_pipeline_artifacts.arn}/*",
          aws_s3_bucket.phil_website.arn,
          "${aws_s3_bucket.phil_website.arn}/*"
        ]
      }
    ]
  })
}

# CodeBuild Project for S3 Deployment
resource "aws_codebuild_project" "s3_build" {
  name         = "phil-s3-build"
  description  = "Build project for Phil's static website"
  service_role = aws_iam_role.s3_build_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "WEBSITE_BUCKET"
      value = aws_s3_bucket.phil_website.bucket
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-east-1"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "pract/s3-buildspec.yml"
  }
}

# GitHub Webhook for S3 Pipeline
# resource "aws_codepipeline_webhook" "s3_pipeline_webhook" {
#   name            = "phil-s3-pipeline-webhook"
#   authentication  = "GITHUB_HMAC"
#   target_action   = "Source"
#   target_pipeline = aws_codepipeline.s3_pipeline.name

#   authentication_configuration {
#     secret_token = var.github_webhook_secret
#   }

#   filter {
#     json_path    = "$.ref"
#     match_equals = "refs/heads/main"
#   }
# }

# resource "github_repository_webhook" "s3_pipeline" {
#   repository = "Ronin"

#   configuration {
#     url          = aws_codepipeline_webhook.s3_pipeline_webhook.url
#     content_type = "json"
#     insecure_ssl = false
#     secret       = var.github_webhook_secret
#   }

#   events = ["push"]
# }

# S3 CodePipeline
resource "aws_codepipeline" "s3_pipeline" {
  name     = "phil-s3-pipeline"
  role_arn = aws_iam_role.s3_pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.s3_pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner               = "Phil-1b3"
        Repo                = "Ronin"
        Branch              = "main"
        OAuthToken          = var.github_token
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.s3_build.name
      }
    }
  }
}

# Outputs
output "s3_pipeline_name" {
  description = "Name of the S3 deployment pipeline"
  value       = aws_codepipeline.s3_pipeline.name
}