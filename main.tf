
# This resource is used to generate uuids. For this example 3 uuids are needed for creating 1 scope and 2 app roles in Audience API
resource "random_uuid" "random_id" {
  count = 3
}

# This creates authorizer application which will have 2 app roles and a scope as mentioned above
module "azurerm_app_reg" {
  source  = "Pujago/azuread-app-registration/azurerm"
  version = "1.0.4"
  display_name = "Sample-application-audience1"
  owners = [data.azuread_client_config.current.object_id]
  # To set application uri to api//<app_id>, you need to update via script, this is not possible in terraform
  identifier_uris = ["api://Sample-application-audience1"]
  prevent_duplicate_names = true
  #use this code for adding scopes
  api = {
    mapped_claims_enabled          = false
    requested_access_token_version = 2
    known_client_applications      = []
    oauth2_permission_scope = [{
      admin_consent_description  = "Role use to secure the api for TestScope_01"
      admin_consent_display_name = "TestScope_02"
      id                         = element(random_uuid.random_id[*].result, 0) # unique uuid 
      type                       = "User"
      value                      = "TestScope_02"
    }]
  }
  #use this code for adding app_roles
  app_role = [
    {
      allowed_member_types = ["Application"]
      description          = "Giving write permission to the apim proxy as 'Query-01.Read'"
      display_name         = "Query-01.Read"
      id                   = element(random_uuid.random_id[*].result, 1) # unique uuid 
      value                = "Query-01.Read"
    },
    {
      allowed_member_types = ["Application"]
      description          = "Giving write permission to the apim proxy as 'Query-01.Write'"
      display_name         = "Query-01.Write"
      id                   = element(random_uuid.random_id[*].result, 2) # unique uuid 
      value                = "Query-01.Write"
    }
  ]
  #use this code for adding api permissions
  required_resource_access = [{
    # Microsoft Graph
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access = [{
      # User.Read
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }]
  }]
  tags = ["Sample application", "terraform"]
}



# This will create client application, add permissions and redirect URIs
module "azurerm_app_reg_client" {
  source  = "Pujago/azuread-app-registration/azurerm"
  version = "1.0.4"
  display_name = "Sample-application-client1"
  owners = [data.azuread_client_config.current.object_id]
  prevent_duplicate_names = true
  #use this code for adding scopes
  api = {
    requested_access_token_version = 2
  }
  #use this code for adding api permissions
  required_resource_access = [
    {
      # Microsoft Graph
      resource_app_id = "00000003-0000-0000-c000-000000000000"

      resource_access = [{
        # User.Read
        id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
        type = "Scope"
      }]
    },
    {
      # Application
      resource_app_id = module.azurerm_app_reg.client_id
      resource_access = [
        {
          id   = module.azurerm_app_reg.app_role_ids["Query-01.Read"]
          type = "Role"
        },
        {
          # Application
          id   = module.azurerm_app_reg.app_role_ids["Query-01.Write"]
          type = "Role"
        }
      ]
    }
  ]
  web = {
    redirect_uris = ["https://dev.simpleterra1.com/", "https://xya1.com/"]
  }
  tags = ["Sample application", "terraform"]
}


# Creates password credentials for client application
module "azurerm_app_reg_client_pwd" {
  source                = "Pujago/azuread_application_password/azurerm"
  version               = "1.0.0"
  application_object_id = module.azurerm_app_reg_client.object_id
  display_name          = "client application password"
}

# Store the password credentials of client application in existing key vault
resource "azurerm_key_vault_secret" "secret" {
  name         = module.azurerm_service_principal_clientapp.display_name
  value        = module.azurerm_app_reg_client_pwd.value
  key_vault_id = data.azurerm_key_vault.main.id
}

# It will pre-authorize client application 
module "azurerm_app_pre_authorized" {
  source                = "Pujago/azure_ad_application_preauthorized/azurerm"
  version               = "1.0.0"

  # application object id of authorized application
  application_object_id = module.azurerm_app_reg.object_id
  
  # application id of Client application
  authorized_app_id     = module.azurerm_app_reg_client.client_id

  # permissions to assign
  permission_ids        = [module.azurerm_app_reg.oauth2_permission_scope_ids["TestScope_02"]]
}



# Creates service principal for Web api (authorizer application)
module "azurerm_service_principal_audienceapp" {
  source         = "Pujago/azuread_service_principal/azurerm"
  version        = "1.0.1"
  application_id = module.azurerm_app_reg.client_id
  owners         = [data.azuread_client_config.current.object_id]

}

# Creates service principal for client application
module "azurerm_service_principal_clientapp" {
  source         = "Pujago/azuread_service_principal/azurerm"
  version        = "1.0.1"
  application_id = module.azurerm_app_reg_client.client_id
  owners         = [data.azuread_client_config.current.object_id]
}






