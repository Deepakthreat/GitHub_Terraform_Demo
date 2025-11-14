### Providers
#OneMSCIUX_Non-Prod
provider "azurerm" {
    tenant_id       = "7a9376d4-7c43-480f-82ba-a090647f651d"  #MSCI OFFICE 365
    subscription_id = "a0bfe367-8299-4495-bec6-59d9688f95d2"  #OneMSCIUX_Non-Prod
    features {}
}

#SSPROD
provider "azurerm" {
    tenant_id       = "7a9376d4-7c43-480f-82ba-a090647f651d"  #MSCI OFFICE 365
    subscription_id = "2382f82d-348c-426c-a1ec-a64503468ae5"  #SharedServices_Prod
    alias           = "SharedServices_Prod"
    features {}
}

#Security_Prod
variable "sentinel" {
    type = map(string)
        default = {
            "rgrp"              = "rgrp-pva2-sm-securitylogs"
            "lanw"              = "lanw-pva2-sm-logs001"
            "subscription_id"   = "a891da20-a4f6-42e4-83eb-fa852bf698f6"
            "tenant_id"         = "7a9376d4-7c43-480f-82ba-a090647f651d"
    }
}
provider "azurerm" {
    alias           = "Security_Prod"
    subscription_id = var.sentinel["subscription_id"]
    tenant_id       = var.sentinel["tenant_id"]
    features {}
}

#AzureAD
provider "azuread" {
  tenant_id       = "7a9376d4-7c43-480f-82ba-a090647f651d"  #MSCI OFFICE 365
}

#TF Version
terraform {
  required_version = "1.0.11"
}

#Provider Versions
terraform {
  required_providers {

    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.88.1"
    }

    azuread = {
      source = "hashicorp/azuread"
      version = "2.12.0"
    }
  }
}

#Backend
terraform {
  backend "azurerm" {
    tenant_id               = "7a9376d4-7c43-480f-82ba-a090647f651d"  #MSCI OFFICE 365
    subscription_id         = "a0bfe367-8299-4495-bec6-59d9688f95d2"  #OneMSCIUX_Non-Prod
    resource_group_name     = "rgrp-dva2-ux-tfstate"  #East US 2 RGRP
    storage_account_name    = "saccdva2uxtfstate001"
    container_name          = "tfstate-ie1-infrastructure"
    key                     = "ux-nonprod-ie1-infrastructure.terraform.tfstate"
    snapshot                = true
  }
}

#Client Config Current
data "azurerm_client_config" "current" {
}
