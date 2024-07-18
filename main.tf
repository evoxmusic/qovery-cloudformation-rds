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
  name                 = "RDS Postgres"
  cpu                  = 250
  memory               = 256
  max_duration_seconds = 1800
  max_nb_restart       = 1
  auto_deploy          = true
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
  healthchecks = {}
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
    },
    {
      key   = "CF_TEMPLATE_PATH"
      value = "cloudformation/cloudformation/main.yaml"
    },
    {
      key   = "VPC_SECURITY_GROUP_ID"
      value = var.VPC_SECURITY_GROUP_ID
    }
  ]
  secrets = [
    {
      key   = "AWS_SECRET_ACCESS_KEY"
      value = var.AWS_SECRET_ACCESS_KEY
    },
    {
      key = "JOB_INPUT_JSON"
      value = templatefile("./cloudformation/input.json.tmpl", {
        master_username       = var.MASTER_USERNAME
        master_password       = var.MASTER_PASSWORD
        database_name         = var.DATABASE_NAME
        vpc_security_group_id = var.VPC_SECURITY_GROUP_ID
      })
    }
  ]
}