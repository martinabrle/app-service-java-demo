param appServiceName string
param appServicePort string
param appServiceTags string

param pgsqlName string
param pgsqlAADAdminGroupName string
param pgsqlAADAdminGroupObjectId string
param pgsqlDbName string
param pgsqlStagingDbName string

param pgsqlSubscriptionId string = subscription().subscriptionId
param pgsqlRG string = resourceGroup().name
param pgsqlTags string = appServiceTags

param logAnalyticsName string
param logAnalyticsSubscriptionId string = subscription().subscriptionId
param logAnalyticsRG string = resourceGroup().name
param logAnalyticsTags string = appServiceTags

param healthCheckPath string = '/'
param stagingHealthCheckPath string = '/'

@secure()
param dbUserName string
@secure()
param dbStagingUserName string

param deploymentClientIPAddress string

param location string = resourceGroup().location

var appServiceTagsArray = json(appServiceTags)
var pgsqlTagsArray = json(pgsqlTags)
var logAnalyticsTagsArray = json(logAnalyticsTags)

module logAnalytics 'components/log-analytics.bicep' = {
  name: 'log-analytics'
  scope: resourceGroup(logAnalyticsSubscriptionId, logAnalyticsRG)
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    tagsArray: logAnalyticsTagsArray
  }
}

module appInsightsModule 'components/app-insights.bicep' = {
  name: 'app-insights'
  params: {
    name: '${appServiceName}-todo-ai'
    location: location
    tagsArray: appServiceTagsArray
    logAnalyticsStringId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module pgsql './components/pgsql.bicep' = {
  name: 'pgsql'
  scope: resourceGroup(pgsqlSubscriptionId, pgsqlRG)
  params: {
    name: pgsqlName
    dbServerAADAdminGroupName: pgsqlAADAdminGroupName
    dbServerAADAdminGroupObjectId: pgsqlAADAdminGroupObjectId
    location: location
    tagsArray: pgsqlTagsArray
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    deploymentClientIPAddress: deploymentClientIPAddress
  }
}

module appService 'components/app-service.bicep' = {
  name: 'app-service'
  params: {
    appServiceName: appServiceName
    appServiceTags: appServiceTags
    healthCheckPath: healthCheckPath
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    location: location
  }
}

module appServiceStagingSlot 'components/app-service-slot.bicep' = {
  name: 'app-service-staging-slot'
  params: {
    appServiceName: appService.outputs.appServiceName
    appServicePlanName: appService.outputs.appServicePlanName
    appServiceTags: appServiceTags
    appServiceSlotName: 'staging'
    healthCheckPath: stagingHealthCheckPath
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    location: location
  }
}

module keyVaultModule 'components/kv.bicep' = {
  name: 'keyvault'
  params: {
    name: '${appServiceName}-kv'
    location: location
    tagsArray: appServiceTagsArray
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module kvSecretSpringDataSourceURL 'components/kv-secret.bicep' = {
  name: 'kv-secret-spring-data-source-url'
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName: 'SPRING-DATASOURCE-URL'
    secretValue: 'jdbc:postgresql://${pgsqlName}.postgres.database.azure.com:5432/${pgsqlDbName}'
  }
}

module kvSecretDbUserName 'components/kv-secret.bicep' = {
  name: 'kv-secret-db-user-name'
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName: 'SPRING-DATASOURCE-USERNAME'
    secretValue: dbUserName
  }
}

module kvSecretStagingSpringDataSourceURL 'components/kv-secret.bicep' = {
  name: 'kv-secret-staging-spring-data-source-url'
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName: 'SPRING-DATASOURCE-URL-STAGING'
    secretValue: 'jdbc:postgresql://${pgsqlName}.postgres.database.azure.com:5432/${pgsqlStagingDbName}'
  }
}

module kvSecretDbStagingUserName 'components/kv-secret.bicep' = {
  name: 'kv-secret-db-staging-user-name'
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    secretName: 'SPRING-DATASOURCE-USERNAME-STAGING'
    secretValue: dbStagingUserName
  }
}

@description('This is the built-in Key Vault Secrets User role. See https://docs.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource keyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup() //keyVault
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

module rbacKVSpringDataSourceURL './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-app-spring-datasource-url'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appService.outputs.appServicePrincipalId
    roleAssignmentNameGuid: guid(appService.outputs.appServiceId, kvSecretSpringDataSourceURL.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVaultModule.outputs.keyVaultName
    kvSecretName: kvSecretSpringDataSourceURL.outputs.kvSecretName
  }
}

module rbacKVSecretDbUserName './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-db-user-name'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appService.outputs.appServicePrincipalId
    roleAssignmentNameGuid: guid(appService.outputs.appServiceId, kvSecretDbUserName.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVaultModule.outputs.keyVaultName
    kvSecretName: kvSecretDbUserName.outputs.kvSecretName
  }
}

module rbacKVSecretDbStagingUserName './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-db-user-name-staging'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appServiceStagingSlot.outputs.appServiceSlotPrincipalId
    roleAssignmentNameGuid: guid(appServiceStagingSlot.outputs.appServiceSlotPrincipalId, kvSecretDbStagingUserName.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVaultModule.outputs.keyVaultName
    kvSecretName: kvSecretDbStagingUserName.outputs.kvSecretName
  }
}

module rbacKVSpringDataSourceURL2 './components/role-assignment-kv-secret.bicep' = {
  name: 'rbac-kv-secret-app-spring-datasource-url2'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appServiceStagingSlot.outputs.appServiceSlotPrincipalId
    roleAssignmentNameGuid: guid(appServiceStagingSlot.outputs.appServiceSlotPrincipalId, kvSecretStagingSpringDataSourceURL.outputs.kvSecretId, keyVaultSecretsUser.id)
    kvName: keyVaultModule.outputs.keyVaultName
    kvSecretName: kvSecretStagingSpringDataSourceURL.outputs.kvSecretName
  }
}

module appServiceSlotConfigNames 'components/app-service-slot-config-names.bicep' = {
  name: 'app-service-slot-config-names'
  dependsOn: [ appServicePARMS ]
  params: {
    appServiceName: appService.outputs.appServiceName
    appSettingNames: [
      'SPRING_DATASOURCE_URL', 'SPRING_DATASOURCE_USERNAME', 'APPLICATIONINSIGHTS_CONNECTION_STRING', 'APPINSIGHTS_INSTRUMENTATIONKEY', 'SPRING_PROFILES_ACTIVE', 'PORT', 'SPRING_DATASOURCE_SHOW_SQL', 'DEBUG_AUTH_TOKEN'
    ]
  }
}

module appServicePARMS 'components/app-service-params.bicep' = {
  name: 'app-service-parms-web'
  dependsOn: [
    rbacKVSecretDbUserName
    rbacKVSpringDataSourceURL
    rbacKVSecretDbStagingUserName
    rbacKVSpringDataSourceURL2
  ]
  params: {
    appServiceName: appService.outputs.appServiceName
    appSettings: [
      {
        name: 'SPRING_DATASOURCE_URL'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=${kvSecretSpringDataSourceURL.outputs.kvSecretName})'
      }
      {
        name: 'SPRING_DATASOURCE_USERNAME'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=${kvSecretDbUserName.outputs.kvSecretName})'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsightsModule.outputs.appInsightsConnectionString
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: appInsightsModule.outputs.appInsightsInstrumentationKey
      }
      {
        name: 'SPRING_PROFILES_ACTIVE'
        value: 'azure'
      }
      {
        name: 'ENVIRONMENT'
        value: 'app-service'
      }
      {
        name: 'PORT'
        value: appServicePort
      }
      {
        name: 'SPRING_DATASOURCE_SHOW_SQL'
        value: 'true'
      }
      {
        name: 'DEBUG_AUTH_TOKEN'
        value: 'true'
      }
    ]
  }
}

module appServiceStagingPARMS 'components/app-service-slot-params.bicep' = {
  name: 'app-service-staging-parms-web'
  dependsOn: [
    appService
    appServiceSlotConfigNames
    rbacKVSecretDbUserName
    rbacKVSpringDataSourceURL
    rbacKVSecretDbStagingUserName
    rbacKVSpringDataSourceURL2
  ]
  params: {
    appServiceName: appService.outputs.appServiceName
    appServiceSlotName: appServiceStagingSlot.outputs.appServiceSlotName
    appSettings: [
      {
        name: 'SPRING_DATASOURCE_URL'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=${kvSecretStagingSpringDataSourceURL.outputs.kvSecretName})'
      }
      {
        name: 'SPRING_DATASOURCE_USERNAME'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.keyVaultName};SecretName=${kvSecretDbStagingUserName.outputs.kvSecretName})'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsightsModule.outputs.appInsightsConnectionString
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: appInsightsModule.outputs.appInsightsInstrumentationKey
      }
      {
        name: 'SPRING_PROFILES_ACTIVE'
        value: 'azure'
      }
      {
        name: 'ENVIRONMENT'
        value: 'app-service'
      }
      {
        name: 'PORT'
        value: appServicePort
      }
      {
        name: 'SPRING_DATASOURCE_SHOW_SQL'
        value: 'true'
      }
      {
        name: 'DEBUG_AUTH_TOKEN'
        value: 'true'
      }
    ]
  }
}
