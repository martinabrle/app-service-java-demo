param appServiceRG string
param appServiceTags string

param pgsqlSubscriptionId string = subscription().subscriptionId
param pgsqlRG string = appServiceRG
param pgsqlTags string = appServiceTags

param logAnalyticsSubscriptionId string = subscription().subscriptionId
param logAnalyticsRG string = appServiceRG
param logAnalyticsTags string = appServiceTags

param location string = deployment().location

var appServiceTagsArray = json(appServiceTags)
var logAnalyticsTagsArray = json(logAnalyticsTags)
var pgsqlTagsArray = json(pgsqlTags)

targetScope = 'subscription'

module logAnalyticsResourceGroup 'components/rg.bicep' = {
  name: 'log-analytics-rg'
  scope: subscription(logAnalyticsSubscriptionId)
  params: {
    name: logAnalyticsRG
    location: location
    tagsArray: logAnalyticsTagsArray
  }
}

module pgsqlResourceGroup 'components/rg.bicep' = {
  name: 'pgsql-rg'
  scope: subscription(pgsqlSubscriptionId)
  params: {
    name: pgsqlRG
    location: location
    tagsArray: pgsqlTagsArray
  }
}

module appServiceResourceGroup 'components/rg.bicep' = {
  name: 'app-service-rg'
  params: {
    name: appServiceRG
    location: location
    tagsArray: appServiceTagsArray
  }
}
