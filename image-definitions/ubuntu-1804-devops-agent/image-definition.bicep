param imageName string
param umiResourceId string
param subnetResourceId string
param sigResourceId string

var sigName = last(split(sigResourceId, '/'))

// Make DevOps Agent
resource image 'Microsoft.Compute/galleries/images@2020-09-30' = {
  name: '${sigName}/${imageName}'
  location: resourceGroup().location
  properties: {
    description: 'Azure DevOps Agent (Ubuntu 18.04)'
    osType: 'Linux'
    osState: 'Generalized'
    identifier: {
      publisher: 'Demo'
      offer: 'UbuntuDevOpsAgent'
      sku: '18.04-LTS'
    }
  }
}

resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  name: 'img-${imageName}'
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umiResourceId}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 30
    vmProfile: {
      vmSize: 'Standard_D1_v2'
      osDiskSizeGB: 30
      vnetConfig: {
        subnetId: subnetResourceId
      }
    }
    source: {
      type: 'PlatformImage'
      publisher: 'Canonical'
      offer: 'UbuntuServer'
      sku: '18.04-LTS'
      version: 'latest'
    }
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: image.id
        runOutputName: imageName
        artifactTags: {}
        replicationRegions: [
          'australiaeast'
        ]
      }
    ]
    customize: [
      {
        type: 'Shell'
        name: 'InstallAzureCli'
        inline: [
          'curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash'
        ]
      }
      {
        type: 'Shell'
        name: 'Docker'
        inline: [
          'sudo apt-get update'
          'sudo apt-get remove docker docker-engine docker.io containerd runc'
          'sudo apt-get -y install apt-transport-https ca-certificates curl gnupg lsb-release'
          'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
          ''
          'echo \\'
          '   \'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \\'
          '    $(lsb_release -cs) stable\' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
          'sudo apt-get update'
          'sudo apt-get -y install docker-ce docker-ce-cli containerd.io'
          '# Enable docker.service'
          'systemctl is-active --quiet docker.service || systemctl start docker.service'
          'systemctl is-enabled --quiet docker.service || systemctl enable docker.service'
          ''
          '# Docker daemon takes time to come up after installing'
          'sleep 10'
          'docker info'
        ]
      }
      {
        type: 'Shell'
        name: 'PullDockerImages'
        inline: [
          'docker pull mcr.microsoft.com/dotnet/sdk:5.0'
        ]
      }
      {
        type: 'Shell'
        name: 'InstallMicosoftPackages'
        inline: [
          'wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb'
          'sudo dpkg -i packages-microsoft-prod.deb'
          'rm packages-microsoft-prod.deb'
          'sudo apt-get update'
        ]
      }
      {
        type: 'Shell'
        name: 'InstallDotNet5SDK'
        inline: [
          'sudo apt-get install -y apt-transport-https'
          'sudo apt-get update'
          'sudo apt-get install -y dotnet-sdk-5.0'
          'sudo apt-get install -y aspnetcore-runtime-5.0'
        ]
      }
      {
        type: 'Shell'
        name: 'InstallUpgrades'
        inline: [
          'sudo apt install unattended-upgrades'
        ]
      }
    ]
  }
  dependsOn: [
    image
  ]
}
