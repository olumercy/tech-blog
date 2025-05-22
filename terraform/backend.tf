terraform {
  // Specifies the backend configuration for Terraform state storage.
  backend "remote" {  
      // Defines the hostname for the Terraform Cloud service.
      hostname = "app.terraform.io"  

      // Specifies the organization within Terraform Cloud.
      organization = "Olumercy-DevOps-Training"  

      workspaces {
         // Defines the workspace name where Terraform state is stored.
         name = "web-blog-access-key"  
      }
  }
}
