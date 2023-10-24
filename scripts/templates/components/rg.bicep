param name string
param location string
param tagsArray object

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: name
  location: location
  tags: tagsArray
}

output name string = resourceGroup.name
