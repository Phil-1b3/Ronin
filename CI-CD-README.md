# CI/CD Pipeline Setup for ECS Deployment

This project sets up a complete CI/CD pipeline using AWS CodePipeline, CodeBuild, ECR, and ECS to automatically build and deploy a containerized web application.

## Architecture Overview

1. **Source**: GitHub repository with your application code
2. **Build**: AWS CodeBuild builds Docker image and pushes to ECR
3. **Deploy**: AWS CodePipeline deploys to ECS Fargate service

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed
- Docker installed (for local testing)
- GitHub repository with your code
- GitHub personal access token

## Setup Instructions

### 1. GitHub Setup

1. Create a GitHub personal access token:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Generate new token with `repo` permissions
   - Save the token securely

### 2. Configure Terraform Variables

1. Copy the example variables file:
   ```bash
   cp Terraform/terraform.tfvars.example Terraform/terraform.tfvars
   ```

2. Edit `Terraform/terraform.tfvars` with your values:
   ```hcl
   github_token = "your_github_personal_access_token"
   ```

3. Update the GitHub configuration in `Terraform/Code-Pipeline.tf`:
   - Replace `YOUR_GITHUB_USERNAME` with your GitHub username
   - Replace `YOUR_REPOSITORY_NAME` with your repository name
   - Update the branch name if different from `main`

### 3. Deploy Infrastructure

1. Deploy ECS infrastructure first:
   ```bash
   cd ECS
   terraform init
   terraform plan
   terraform apply
   ```

2. Deploy CodePipeline infrastructure:
   ```bash
   cd ../Terraform
   terraform init
   terraform plan
   terraform apply
   ```

### 4. Push Code to GitHub

Ensure your repository contains:
- `buildspec.yml` (in root directory)
- `pract/Dockerfile`
- `pract/index.html`
- `pract/practice.js`
- Any other application files

### 5. Test the Pipeline

1. Push changes to your GitHub repository
2. CodePipeline will automatically trigger
3. Monitor the pipeline in AWS Console

## File Structure

```
.
├── buildspec.yml              # CodeBuild configuration
├── ECS/
│   └── main.tf               # ECS cluster, service, task definition
├── Terraform/
│   ├── Code-Pipeline.tf      # CodePipeline, CodeBuild, IAM roles
│   └── terraform.tfvars      # Your configuration variables
└── pract/
    ├── Dockerfile            # Docker configuration
    ├── index.html           # Web application
    └── practice.js          # JavaScript code
```

## Key Components

### CodeBuild (`buildspec.yml`)
- Builds Docker image from `pract/` directory
- Pushes image to ECR repository
- Creates `imagedefinitions.json` for ECS deployment

### ECS Infrastructure (`ECS/main.tf`)
- ECR repository for Docker images
- ECS cluster running on Fargate
- Task definition with container specifications
- Service with desired count and networking

### CodePipeline (`Terraform/Code-Pipeline.tf`)
- Source stage: GitHub repository
- Build stage: CodeBuild project
- Deploy stage: ECS service update

## Troubleshooting

### Common Issues

1. **ECR Authentication**: Ensure CodeBuild role has ECR permissions
2. **GitHub Connection**: Verify personal access token has correct permissions
3. **ECS Deployment**: Check task definition and service configuration
4. **Networking**: Ensure security groups allow HTTP traffic on port 80

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster phils-cluster --services phils-service

# View CodeBuild logs
aws logs describe-log-groups --log-group-name-prefix /aws/codebuild/phils-build

# Check ECR images
aws ecr describe-images --repository-name phils-service

# Test Docker image locally
docker run -p 8080:80 your-account-id.dkr.ecr.us-west-2.amazonaws.com/phils-service:latest
```

## Security Notes

- Keep your GitHub token secure and never commit it to version control
- Use IAM roles with minimal required permissions
- Regularly rotate access tokens
- Consider using AWS Secrets Manager for sensitive data

## Next Steps

1. Set up monitoring with CloudWatch
2. Add automated testing stages
3. Implement blue/green deployments
4. Add notification systems (SNS/Slack)
5. Set up multiple environments (dev/staging/prod)
