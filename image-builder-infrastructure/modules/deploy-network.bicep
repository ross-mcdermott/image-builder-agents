@description('Location for the resources')
param location string

@description('Virtual Network resource name')
param vnetName string

resource vnet 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  name: vnetName
  location: location
  tags: {}
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.1.0/24'
      ]
    }
    subnets: [
      {
        name: 'ImageBuildSubnet'
        properties: {
          addressPrefix: '10.10.1.0/27'
          privateLinkServiceNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsgAib.id
          }
        }
      }
      {
        name: 'PrivateEndpoints'
        properties: {
          addressPrefix: '10.10.1.32/27'
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsgPep.id
          }
        }
      }
    ]
  }
}

resource nsgAib 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: 'nsg-${vnetName}-image-build-subnet'
  location: location
  properties: {
    securityRules: [ 
      { 
        name: 'AzureImageBuilderNsgRule'
        properties: {
          description: 'Allow Image Builder Private Link Access to Proxy VM'
          access: 'Allow'
          direction: 'Inbound'
          priority: 400
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationPortRange: '60000-60001'
        }
      }
    ]
  }
}

resource nsgPep 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: 'nsg-${vnetName}-private-endpoints'
  location: location
  properties: {
    securityRules: [ ]
  }
}

output vnetResourceId string = vnet.id
output subnetImageBuilderResourceId string = '${vnet.id}/subnets/ImageBuildSubnet'
