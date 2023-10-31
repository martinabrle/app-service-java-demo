param appServiceName string 
param appServiceTags string
param healthCheckPath string = '/'
param logAnalyticsWorkspaceId string
param location string = resourceGroup().location

var appServiceTagsArray = json(appServiceTags)

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${appServiceName}-plan'
  location: location
  tags: appServiceTagsArray
  properties: {
    reserved: true
  }
  sku: {
    name: 'S2'
  }
  kind: 'linux'
}

resource appServicePlanDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServiceName}-app-logs'
  scope: appServicePlan
  properties: {
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

resource appService 'Microsoft.Web/sites@2021-03-01' = {
  name: appServiceName
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

// resource appServiceStaging 'Microsoft.Web/sites/slots@2021-03-01' = {
//   parent: appService
//   name: 'staging'
//   location: location
//   tags: appServiceTagsArray
//   identity: {
//     type: 'SystemAssigned'
//   }
//   properties: {
//     serverFarmId: appServicePlan.id
//     siteConfig: {
//       linuxFxVersion: 'JAVA|11-java11'
//       scmType: 'None'
//     }
//   }
// }

resource appServiceDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServiceName}-app-logs'
  scope: appService
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

// resource appServiceStagingDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: '${appServiceName}-staging-app-logs'
//   scope: appServiceStaging
//   properties: {
//     logs: [
//       {
//         categoryGroup: 'allLogs'
//         enabled: true
//       }
//       {
//         categoryGroup: 'audit'
//         enabled: true
//       }
//     ]
//     metrics: [
//       {
//         category: 'AllMetrics'
//         enabled: true
//       }
//     ]
//     workspaceId: logAnalyticsWorkspaceId
//   }
// }
output outboundIpAddresses string = appService.properties.outboundIpAddresses
output possibleOutboundIpAddresses string = appService.properties.possibleOutboundIpAddresses
output appServiceId string = appService.id
output appServiceName string = appService.name
output appServicePrincipalId string = appService.identity.principalId
output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name

