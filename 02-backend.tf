terraform {
  #   backend "s3" {
  #     bucket         = "lero-terraform-state-backend-prd"
  #     key            = "terraform-devops.tfstate"
  #     region         = "us-east-1"
  #     dynamodb_table = "terraform_state"
  #   }
  backend "local" {
    path = "terraform-prod.tfstate"
  }
}
