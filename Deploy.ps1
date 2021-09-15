param(
    [string] $SubscriptionId
)

$deploymentPrefix = [DateTime]::UtcNow.ToString('yyyyMMddHHmmss')
$index = 1

az deployment sub create --location australiaeast `
    --subscription $SubscriptionId `
    --template-file ./azure-deploy.bicep `
    --parameters ./parameters.jsonc `
    --parameters deploymentPrefix=$deploymentPrefix `
    --name "$($deploymentPrefix)-$($index)" `
    --output none
