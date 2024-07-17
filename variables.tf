variable "qovery_access_token" {
  description = "Qovery API token"
  type        = string
}

variable "qovery_organization_id" {
  description = "Qovery Organization ID"
  type        = string
}

variable "qovery_cluster_id" {
  description = "My Qovery Test Cluster ID"
  type        = string
}

variable "qovery_environment_id" {
  description = "Qovery Environment ID"
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