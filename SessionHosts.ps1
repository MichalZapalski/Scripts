$hostpools = @(
    "NameOfHostPool"
)

$out = foreach ($hostpool in $hostpools) {
    Get-AzWvdSessionHost -HostPoolName $hostpool -ResourceGroupName NameOfResourceGroup | Select-Object UserPrincipalName, Name, LastHeartBeat | Export-Csv -Path "C:\Support\hosts.csv" -NoTypeInformation
}
$out