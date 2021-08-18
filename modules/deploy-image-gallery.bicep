@description('Location for the resources')
param location string

@description('Shared Image Gallery Resource Name')
param sigName string

resource wvdsig 'Microsoft.Compute/galleries@2020-09-30' = {
  name: sigName
  location: location
}

output resourceId string = wvdsig.id
