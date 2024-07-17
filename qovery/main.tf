terraform {
  required_providers {
    qovery = {
      source = "qovery/qovery"
    }
  }
}

provider "qovery" {
  token = var.qovery_access_token
}

resource "qovery_job" "my_job" {
  # Required
  environment_id = var.qovery_environment_id
  name           = "rds-test"
  cpu            = 250
  memory         = 256

  source = {
    docker = {
      git_repository = {
        url       = "https://github.com/evoxmusic/qovery-cloudformation-rds.git"
        branch    = "main"
        root_path = "/qovery/Dockerfile"
      }
    }
  }

  healthchecks = {
    readiness_probe = {
      type = {}
      initial_delay_seconds = 30
      period_seconds        = 10
      timeout_seconds       = 10
      success_threshold     = 1
      failure_threshold     = 3
    }
    liveness_probe = {
      type = {}
      initial_delay_seconds = 30
      period_seconds        = 10
      timeout_seconds       = 10
      success_threshold     = 1
      failure_threshold     = 3
    }
  }
  schedule = {
    lifecycle_type = "CLOUDFORMATION"
    on_start = {
      arguments = ["start"]
    }
  }
}