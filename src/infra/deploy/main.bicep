@description('The location to deploy our resources to. Default is location of the resource group')
param location string = resourceGroup().location
//param applicationName string = 'devbg-store'

param uniqueSeed string = '${resourceGroup().id}-${deployment().name}'

@description('DON"T SHARE YOUR CREDENTIALS IN THIS WAY!!!!')
param azureContainerRegistry string = 'storeproductapi20230308193835.azurecr.io'
param azureContainerRegistryUsername string = 'StoreProductApi20230308193835'
@secure()
param azureContainerRegistryPassword string = '2WlqdxH75QsdYnim2BhPzrmseCMsNQiub1OGKC+xAw+ACRA6Vxcd'



////////////////////////////////////////////////////////////////////////////////
// Infrastructure
////////////////////////////////////////////////////////////////////////////////

module containerAppsEnvironment 'containerapps/modules/infra/container-apps-env.bicep' = {
  name: '${deployment().name}-infra-container-app-env'
  params: {
    location: location
    uniqueSeed: uniqueSeed
  }
}

module cosmos 'containerapps/modules/infra/cosmos-db.bicep' = {
  name: '${deployment().name}-infra-cosmos-db'
  params: {
    location: location
    uniqueSeed: uniqueSeed
  }
}

////////////////////////////////////////////////////////////////////////////////
// Dapr components
////////////////////////////////////////////////////////////////////////////////


module daprStateStore 'containerapps/modules/dapr/statestore.bicep' = {
  name: '${deployment().name}-dapr-statestore'
  params: {
    containerAppsEnvironmentName: containerAppsEnvironment.outputs.name
    cosmosDbName: cosmos.outputs.cosmosDbName
    cosmosCollectionName: cosmos.outputs.cosmosCollectionName
    cosmosUrl: cosmos.outputs.cosmosUrl
    cosmosKey: cosmos.outputs.cosmosKey
  }
}


////////////////////////////////////////////////////////////////////////////////
// Container apps
////////////////////////////////////////////////////////////////////////////////

module inventoryApi 'containerapps/modules/apps/inventory-api.bicep' = {
  name: '${deployment().name}-inventory-api'
  dependsOn: [
    daprStateStore
  ]
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    azureContainerRegistry: azureContainerRegistry
    azureContainerRegistryPassword: azureContainerRegistryPassword
    azureContainerRegistryUsername: azureContainerRegistryUsername
  }
}

module productApi 'containerapps/modules/apps/product-api.bicep' = {
  name: '${deployment().name}-app-basket-api'
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    azureContainerRegistry: azureContainerRegistry
    azureContainerRegistryPassword: azureContainerRegistryPassword
    azureContainerRegistryUsername: azureContainerRegistryUsername
  }
}

module blazorClient 'containerapps/modules/apps/store.bicep' = {
  name: '${deployment().name}-store'
  dependsOn: [
    inventoryApi
    productApi
  ]
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    azureContainerRegistry: azureContainerRegistry
    azureContainerRegistryPassword: azureContainerRegistryPassword
    azureContainerRegistryUsername: azureContainerRegistryUsername
  }
}
