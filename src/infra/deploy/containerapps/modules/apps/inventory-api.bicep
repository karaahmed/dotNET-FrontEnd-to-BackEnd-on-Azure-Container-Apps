param location string
param containerAppsEnvironmentId string

param azureContainerRegistry string
param azureContainerRegistryUsername string
@secure()
param azureContainerRegistryPassword string

var container_name = 'inventory-api'

resource inventoryApi 'Microsoft.App/containerApps@2022-10-01' = {
  name: container_name
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    template: {
      containers: [
        {
          name: container_name
          image: '${azureContainerRegistry}/storeinventoryapi:latest'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://0.0.0.0:80'
            }
            {            
              name: 'ApplicationMapNodeName'
              value: 'Inventory API'
            }
          ]      
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }

    }
    configuration: {
      secrets: [
        {
          name: 'containerregistrypasswordref'
          value: azureContainerRegistryPassword
        }
      ]
      registries: [
        {
          server: azureContainerRegistry
          username: azureContainerRegistryUsername
          passwordSecretRef: 'containerregistrypasswordref'
        }
      ]
      activeRevisionsMode: 'single'
      dapr: {
        enabled: true
        appId: container_name
        appPort: 80
      }
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: true
      }
    }
  }
}
