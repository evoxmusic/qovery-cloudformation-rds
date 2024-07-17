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
  environment_id       = var.qovery_environment_id
  name                 = "rds-test"
  cpu                  = 250
  memory               = 256
  max_duration_seconds = 300
  max_nb_restart       = 1
  source = {
    docker = {
      git_repository = {
        url       = "https://github.com/evoxmusic/qovery-cloudformation-rds.git"
        branch    = "main"
        root_path = "/"
      }
      dockerfile_path = "Dockerfile"
    }
  }
  healthchecks = {
    readiness_probe = {
      type = {
        exec = {
          command = ["sh", "-c", "echo 'ready'"]
        }
      }
      initial_delay_seconds = 30
      period_seconds        = 10
      timeout_seconds       = 10
      success_threshold     = 1
      failure_threshold     = 3
    }
    liveness_probe = {
      type = {
        exec = {
          command = ["sh", "-c", "echo 'ready'"]
        }
      }
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
      entrypoint = ""
    }
    on_stop = {
      arguments = ["stop"]
      entrypoint = ""
    }
    on_delete = {
      arguments = ["delete"]
      entrypoint = ""
    }
  }
  environment_variables = [
    {
      key   = "AWS_ACCESS_KEY_ID"
      value = var.AWS_ACCESS_KEY_ID
    },
    {
      key   = "AWS_DEFAULT_REGION"
      value = var.AWS_DEFAULT_REGION
    }
  ]
  secrets = [
    {
      key   = "AWS_SECRET_ACCESS_KEY"
      value = var.AWS_SECRET_ACCESS_KEY
    }
  ]
}