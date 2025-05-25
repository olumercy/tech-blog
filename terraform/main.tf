# Configure the AWS Provider
/*provider "aws" {
  region = "eu-west-1"
  #access_key = var.access_key
  #secret_key = var.secret_key
  token      = var.token 
 assume_role {
    role_arn = "arn:aws:iam::457087769557:role/Terraformoidc-role"
  }
}
*/

provider "aws" {
  region = var.region
}

provider "aws" {
  alias = "eu-west-2"
  region = "eu-west-2"
  
}
provider "random" {}

data "aws_caller_identity" "current" {}