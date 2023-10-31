param name string

param dbServerAADAdminGroupObjectId string
param dbServerAADAdminGroupName string
param deploymentClientIPAddress string = ''
param incomingIpAddresses string = '1.1.1.2,3.3.3.3'

param location string
param tagsArray object

param logAnalyticsWorkspaceId string

resource postgreSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: name
  location: location
  tags: tagsArray
  sku: {
    name: 'Standard_B1ms' //'Standard_B2s'
    tier: 'Burstable'
  }
  properties: {
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    version: '14'
    storage: {
      storageSizeGB: 32
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled' // 'Enabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
}

resource postgreSQLServerAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2023-03-01-preview' = {
  parent: postgreSQLServer
  name: dbServerAADAdminGroupObjectId
  properties: {
    principalType: 'Group'
    principalName: dbServerAADAdminGroupName
    tenantId: subscription().tenantId
  }
}

resource allowAllAzureIPsFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-12-01' = if (empty(incomingIpAddresses)) {
  name: 'AllowAllAzureIps'
  parent: postgreSQLServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource allowClientIPFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-03-08-preview' = if (!empty(deploymentClientIPAddress)) {
  name: 'AllowDeploymentClientIP'
  parent: postgreSQLServer
  properties: {
    endIpAddress: deploymentClientIPAddress
    startIpAddress: deploymentClientIPAddress
  }
}

var incomingIpAddressesArray = split(incomingIpAddresses, ',')

resource allowAppServiceIPs 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = [for incomingIpAddress in incomingIpAddressesArray: {
  name: 'AppService_${replace(incomingIpAddress, '.', '_')}'
  parent: postgreSQLServer
  properties: {
    startIpAddress: incomingIpAddress
    endIpAddress: incomingIpAddress
  }
}]

resource allowAllIPsFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-03-08-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: postgreSQLServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource postgreSQLServerDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-db-logs'
  dependsOn: [
    allowAllAzureIPsFirewallRule
  ]
  scope: postgreSQLServer
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
