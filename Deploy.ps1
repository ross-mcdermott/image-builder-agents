param(
    [string] $SubscriptionId
)

$deploymentPrefix = [DateTime]::UtcNow.ToString('yyyyMMddHHmmss')
$index = 1

az deployment sub create --location australiaeast `
    --subscription $SubscriptionId `
    --template-file ./image-builder-infrastructure/azure-deploy.bicep `
    --parameters ./image-builder-infrastructure/parameters.jsonc `
    --parameters deploymentPrefix=$deploymentPrefix `
    --name "$($deploymentPrefix)-$($index)" `
    --output none
