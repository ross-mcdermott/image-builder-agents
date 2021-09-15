// -------------- scope --------------
// set scope to subscription. 
targetScope = 'subscription'

// ------------ parameters -----------
@description('Resource location')
param location string

@description('Deployment prefix to identify the deployment in the Azure Portal')
param deploymentPrefix string = utcNow()

@description('Infrastructure resource group')
param infastructureResourceGroupName string

@description('Image management resource group')
param imageManagementResourceGroupName string

// UAI name
var managedIdentityName = 'umi-image-build'
var vnetName = 'vnet-image-build'
var sigName = 'sig_image_management'

// Resource Groups
resource infrastructure_rg_resource 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: infastructureResourceGroupName
  location: location
}

resource image_rg_resource 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: imageManagementResourceGroupName
  location: location
}

resource imageCreationRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: '21162358-bc1f-4707-85ee-783efbafa763' // constant value for this role.
  properties: {
    roleName: 'Custom Role - Azure Image Builder Service Image Creation'
    description: 'Azure Image Builder Service Image Creation Role'
    type: 'customRole'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/galleries/read'
          'Microsoft.Compute/galleries/images/read'
          'Microsoft.Compute/galleries/images/versions/read'
          'Microsoft.Compute/galleries/images/versions/write'
          'Microsoft.Compute/images/write'
          'Microsoft.Compute/images/read'
        ]
        notActions: [
        ]
        dataActions: [
        ]
        notDataActions: [
        ]
      }
    ]
    assignableScopes: [
      '/subscriptions/${subscription().subscriptionId}'
    ]
  }
}


resource aibNetworkServiceRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: '16035cd1-94e2-48d6-aab9-f13231dfb9a1' // constant value for this role.
  properties: {
    roleName: 'Custom Role - Azure Image Builder Service Networking'
    description: 'Azure Image Builder Service Networking Role'
    type: 'customRole'
    permissions: [
      {
        actions: [
          'Microsoft.Network/virtualNetworks/read'
          'Microsoft.Network/virtualNetworks/subnets/join/action'
        ]
        notActions: [
        ]
        dataActions: [
        ]
        notDataActions: [
        ]
      }
    ]
    assignableScopes: [
      '/subscriptions/${subscription().subscriptionId}'
    ]
  }
}

module managed_identity_module './modules/deploy-managed-identity.bicep' = {
  scope: infrastructure_rg_resource
  name: '${deploymentPrefix}-identities'
  params: {
    location: location
    managedIdentityResourceName: managedIdentityName
  }
}

module role_assignment_image_creation_module './modules/apply-role-assignments.bicep' = {
  name: '${deploymentPrefix}-role-image'
  scope: image_rg_resource
  params: {
    assignments: [
      {
        roleDefinitionId: imageCreationRole.id
        principalId: managed_identity_module.outputs.principalId
      }
    ]
  }
  dependsOn: [
    managed_identity_module
  ]
}

module role_assignment_network_service_module './modules/apply-role-assignments.bicep' = {
  name: '${deploymentPrefix}-role-network'
  scope: infrastructure_rg_resource
  params: {
    assignments: [
      {
        roleDefinitionId: aibNetworkServiceRole.id
        principalId: managed_identity_module.outputs.principalId
      }
    ]
  }
  dependsOn: [
    managed_identity_module
  ]
}

module network_module './modules/deploy-network.bicep' = {
  scope: infrastructure_rg_resource
  name: '${deploymentPrefix}-network'
  params: {
    location: location
    vnetName: vnetName
  }
}

module sig_module './modules/deploy-image-gallery.bicep' = {
  scope: image_rg_resource
  name: '${deploymentPrefix}-image-gallery'
  params: {
    location: location
    sigName: sigName
  }
}

module img_devops_module './image-definitions/ubuntu-1804-devops-agent/image-definition.bicep' = {
  scope: image_rg_resource
  name: '${deploymentPrefix}-devops-image'
  params: {
    imageName: 'ubuntu-1804-devops-agent'
    sigResourceId: sig_module.outputs.resourceId
    subnetResourceId: network_module.outputs.subnetImageBuilderResourceId
    umiResourceId: managed_identity_module.outputs.resourceId
  }
}

output sigResourceId string = sig_module.outputs.resourceId
