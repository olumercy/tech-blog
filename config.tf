terraform { 
  required_providers {
    // Defines the AWS provider configuration
    aws = {
      // Specifies the source of the provider, in this case, HashiCorp's AWS provider
      source  = "hashicorp/aws"

      // Defines the required version of the AWS provider
      version = "~> 5.0"

           
    }
  }
}
