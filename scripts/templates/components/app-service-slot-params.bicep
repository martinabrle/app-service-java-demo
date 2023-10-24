param appServiceName string
param appServiceSlotName string 
param appSettings array

resource appService 'Microsoft.Web/sites@2022-09-01' existing = {
  name: appServiceName
}

resource appServiceSlot 'Microsoft.Web/sites/slots@2022-09-01' existing = {
  parent: appService
  name: appServiceSlotName
}

resource appServicePARMS 'Microsoft.Web/sites/slots/config@2022-09-01' = {
  name: 'web'
  parent: appServiceSlot
  kind: 'string'
  properties: {
    appSettings: appSettings
  }
}
