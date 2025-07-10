variable "github_token" {
   description = "GitHub personal access token for CodePipeline"
   type        = string
   sensitive   = true
 }

 variable "github_webhook_secret" {
   description = "Secret token for GitHub webhook authentication"
   type        = string
   sensitive   = true
   default     = "github token"
 }

 variable "tag_name" {
   description = "Tag name for Docker images in the pipeline"
   type        = string
   default     = "latest"
 }
