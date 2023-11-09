Connect-AzAccount

Set-AzContext -SubscriptionId "6765aff3-c21b-4e58-aac1-d719cd853dd4"

$resourceGroupName = "ets-wrkp-rg-InstPort-avd-eastus-001"
$hostPoolName = "ets-wrkp-hpool-InstPort-prd-pi-avd-eastus-001"

$vms = Get-AzVm -ResourceGroupName $resourceGroupName

$vmsInHostPool = $vms | Where-Object { $_.Tags.hostpool_name -eq $hostPoolName }

foreach ($vm in $vmsInHostPool)
{
            $vm.HardwareProfile.VmSize = 'Standard_E2s_v3'
            Update-AzVM -VM $vm -ResourceGroupName 'ets-wrkp-rg-InstPort-avd-eastus-001'
            

}