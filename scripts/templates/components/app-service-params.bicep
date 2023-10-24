param appServiceName string 
param appSettings array

resource appService 'Microsoft.Web/sites@2022-09-01' existing = {
  name: appServiceName
}

resource appServicePARMS 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'web'
  parent: appService
  kind: 'string'
  properties: {
    appSettings: appSettings
  }
}
