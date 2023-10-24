param appServiceName string 
param appServicePlanName string 
param appServiceSlotName string
param appServiceTags string
param healthCheckPath string = '/'
param logAnalyticsWorkspaceId string
param location string = resourceGroup().location

var appServiceTagsArray = json(appServiceTags)

resource appService 'Microsoft.Web/sites@2022-09-01' existing = {
  name: appServiceName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: appServicePlanName
}

resource appServiceSlot 'Microsoft.Web/sites/slots@2022-09-01' = {
  parent: appService
  name: appServiceSlotName
  location: location
  tags: appServiceTagsArray
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'JAVA|11-java11'
      scmType: 'None'
      healthCheckPath: healthCheckPath
    }
  }
}

resource appServiceStagingDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServiceName}-${appServiceSlotName}-app-logs'
  scope: appServiceSlot
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

output appServiceId string = appService.id
output appServiceName string = appService.name
output appServicePrincipalId string = appService.identity.principalId

output appServiceSlotId string = appServiceSlot.id
output appServiceSlotName string = appServiceSlot.name
output appServiceSlotPrincipalId string = appServiceSlot.identity.principalId
