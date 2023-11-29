// Deploys PostgreSQL server with firewall rules; requires inactive rules (those not returned by this module in validFirewallRules) to be deleted by script

@description('Name of the PostgreSQL database server, must be unique across Azure, as the FQDN of the server will be <name>.postgres.database.azure.com.')
param name string

@description('Object ID of the Azure AD group that will be the admin of the database server. Must be a valid AAD User Group Object ID.')
param dbServerAADAdminGroupObjectId string

@description('Name of the Azure AD group that will be the admin of the database server. Must be a valid AAD User Group name.')
param dbServerAADAdminGroupName string

@description('IP Address if the deployment / configuration client, for example the IP address of the Azure DevOps agent. If empty, no IP address will be allowed.')
param deploymentClientIPAddress string = ''

@description('Comma separated list of IP addresses to allow access to the database server. If empty, all Azure IPs will be allowed.')
param incomingIpAddresses string = ''

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
var incomingIpAddressesUniqueArray = union(incomingIpAddressesArray, incomingIpAddressesArray)

resource allowAppServiceIPs 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = [for incomingIpAddress in incomingIpAddressesUniqueArray: {
  name: 'AppService_${replace(incomingIpAddress, '.', '_')}'
  parent: postgreSQLServer
  properties: {
    startIpAddress: incomingIpAddress
    endIpAddress: incomingIpAddress
  }
}]

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

var tmpAppServiceIPs = empty(incomingIpAddressesUniqueArray) ? [allowAllAzureIPsFirewallRule.name] : map(incomingIpAddressesUniqueArray, item => 'AppService_${replace(item, '.', '_')}')
var tmpDeploymentClientIPAddressArray = empty(deploymentClientIPAddress) ? [] : [allowClientIPFirewallRule.name]

var appServiceIPs = union(tmpDeploymentClientIPAddressArray, tmpAppServiceIPs)

output validFirewallRules array = appServiceIPs
