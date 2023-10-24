param name string
param rg string 

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: name
  scope: resourceGroup(rg)
}

output principalId string = identity.properties.principalId
