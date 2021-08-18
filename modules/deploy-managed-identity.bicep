@description('Location for the resources')
param location string

@description('Managed Identity Resource Name to create')
param managedIdentityResourceName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityResourceName
  location: location
}

output resourceId string = managedIdentity.id
output principalId string  = managedIdentity.properties.principalId
