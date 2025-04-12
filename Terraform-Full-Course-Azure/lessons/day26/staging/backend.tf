terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstagebackend2024piyush"
    container_name      = "tfstate"
    key                 = "stage.tfstate"
  }
}

provider "azurerm" {
  features {}
}