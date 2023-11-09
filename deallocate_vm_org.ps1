$metadata = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Proxy $Null -Uri http://169.254.169.254/metadata/instance?api-version=2021-01-01
$authorizationToken = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method Get -Proxy $Null -Uri http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-01-01&resource=https://management.azure.com/

$subscriptionId = $metadata.compute.subscriptionId
$resourceGroupName = $metadata.compute.resourceGroupName
$vmName = $metadata.compute.name
$accessToken = $authorizationToken.access_token

$RestartEvents = Get-EventLog -LogName System -After (Get-Date).AddMinutes(-1) |? {($_.EventID -eq 1074) -and ($_.Message -match "restart" )}
$SessionCount = (query user | Measure-Object | select Count).count - 1 # remove headline

if (($SessionCount -gt 1) -or ($RestartEvents.count -ge 1))
{
              # skip deallocate because of user-sessions or initiated reboot
} else {
              Invoke-WebRequest -UseBasicParsing -Headers @{ Authorization ="Bearer $accessToken"} -Method POST -Proxy $Null -Uri https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$vmName/deallocate?api-version=2021-03-01 -ContentType "application/json"
}
