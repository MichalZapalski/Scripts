Connect-AzAccount

Set-AzContext -SubscriptionId ""

$resourceGroupName = ""
$hostPoolName = ""

$vms = Get-AzVm -ResourceGroupName $resourceGroupName

$vmsInHostPool = $vms | Where-Object { $_.Tags.hostpool_name -eq $hostPoolName }

foreach ($vm in $vmsInHostPool)
{
            $vm.HardwareProfile.VmSize = 'Standard_E2s_v3'
            Update-AzVM -VM $vm -ResourceGroupName ''
            


}
