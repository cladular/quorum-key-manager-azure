resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azapi_resource" "managed_environment" {
  name      = "cae-${var.name}"
  location  = var.location
  parent_id = var.resource_group_id
  type      = "Microsoft.App/managedEnvironments@2022-06-01-preview"

  body = jsonencode({
    properties = {
      vnetConfiguration = {
        infrastructureSubnetId = var.subnet_id
        internal               = false
      },
      zoneRedundant = false
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.this.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.this.primary_shared_key
      } }
    }
  })
}

resource "azapi_resource" "storage" {
  type      = "Microsoft.App/managedEnvironments/storages@2022-06-01-preview"
  name      = "storage-${var.name}"
  parent_id = azapi_resource.managed_environment.id
  body = jsonencode({
    properties = {
      azureFile = {
        accountName = var.storage_account_name
        accountKey  = var.storage_account_key
        shareName   = var.share_name
        accessMode  = "ReadOnly"
      }
    }
  })
}

resource "azapi_resource" "container_app" {
  name      = "ctap-${var.name}"
  location  = var.location
  parent_id = var.resource_group_id
  type      = "Microsoft.App/containerApps@2022-06-01-preview"

  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    properties : {
      managedEnvironmentId = azapi_resource.managed_environment.id
      configuration = {
        ingress = {
          external   = true
          targetPort = 8080
          transport  = "http"

        }
        secrets = [
          { name = "db-user", value = "${var.db_user}@${var.db_host}" },
          { name = "db-password", value = var.db_password }
        ]
      }
      template = {
        initContainers = [
          {
            name  = "key-manager-migration"
            image = "docker.io/consensys/quorum-key-manager"
            env = [
              { name = "DB_HOST", value = var.db_host },
              { name = "DB_TLS_SSLMODE", value = "require" },
              { name = "DB_USER", secretRef = "db-user" },
              { name = "DB_PASSWORD", secretRef = "db-password" },
              { name = "DB_DATABASE", value = var.db_database },
            ]
            command = ["/main"]
            args    = ["migrate", "up"]
            resources = {
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
        ]
        containers = [
          {
            name  = "key-manager"
            image = "docker.io/consensys/quorum-key-manager"
            env = [
              { name = "DB_HOST", value = var.db_host },
              { name = "DB_TLS_SSLMODE", value = "require" },
              { name = "DB_USER", secretRef = "db-user" },
              { name = "DB_PASSWORD", secretRef = "db-password" },
              { name = "DB_DATABASE", value = var.db_database },
              { name = "HTTP_HOST", value = "0.0.0.0" },
              { name = "HTTP_PORT", value = "8080" },
              { name = "HEALTH_PORT", value = "8081" },
              { name = "MANIFEST_PATH", value = "/manifests" }
            ]
            command = ["/main"]
            args    = ["run"]
            resources = {
              cpu    = 0.5
              memory = "1.0Gi"
            }
            volumeMounts = [
              {
                mountPath  = "/manifests"
                volumeName = var.share_name
              }
            ]
            probes = [
              {
                type = "Liveness"
                httpGet = {
                  port   = 8081
                  path   = "/live"
                  scheme = "HTTP"
                }
              },
              {
                type = "Readiness"
                httpGet = {
                  port   = 8081
                  path   = "/ready"
                  scheme = "HTTP"
                }
              }
            ]
          }
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
        volumes = [
          {
            name        = var.share_name
            storageType = "AzureFile"
            storageName = "storage-${var.name}"
          }
        ]
      }
    }
  })

  response_export_values = ["properties.configuration.ingress.fqdn"]
}
