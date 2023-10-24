param appServiceName string 
param appSettingNames array

resource appService 'Microsoft.Web/sites@2021-03-01' existing = {
  name: appServiceName
}


resource appServiceSlotConfigNames 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'slotConfigNames'
  kind: 'string'
  parent: appService
  //dependsOn: [ appServicePARMS ]
  properties: {
    appSettingNames: appSettingNames
  }
}
