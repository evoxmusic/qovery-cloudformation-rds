variable "qovery_access_token" {
  description = "Qovery API token"
  type        = string
}

variable "qovery_environment_id" {
  description = "Qovery Environment ID where you will deploy the job"
  type        = string
}

variable "VPC_SECURITY_GROUP_ID" {
    description = "RDS VPC Security Group ID"
    type        = string
}

variable "AWS_ACCESS_KEY_ID" {
  description = "AWS Access Key ID for Cloudformation and the create resources"
  type        = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS Secret Access Key for Cloudformation and the create resources"
  type        = string
}

variable "AWS_DEFAULT_REGION" {
  description = "AWS Region for Cloudformation and the create resources"
  type        = string
  default     = "us-east-2"
}

variable "MASTER_USERNAME" {
    description = "Master username for the database"
    type        = string
}

variable "MASTER_PASSWORD" {
    description = "Master password for the database"
    type        = string
}

variable "DATABASE_NAME" {
    description = "Database name"
    type        = string
}