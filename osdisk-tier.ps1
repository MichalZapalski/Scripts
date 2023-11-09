$resourceGroupName = "ETS-WRKP-RG-W11TEST-AVD-EASTUS-001"
$performanceTier='P10'
$diskUpdateConfig = New-AzDiskUpdateConfig -Tier $performanceTier



$que = "resources | where type == 'microsoft.compute/disks' and resourceGroup contains 'w11test' and name contains 'osdisk' | distinct name"
$disk = Search-AzGraph -Query $que



$disk | ForEach-Object {
    Write-Host $_.name -ForegroundColor Green
try {
    $ErrorActionPreference = "Stop";
    $diskti = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $_.name
    if ($diskti.Tier -ne $performanceTier) {
        Write-Host "Changing performance tier from" $diskti.Tier "to" $performanceTier "for" $_.name
        Update-AzDisk -ResourceGroupName $resourceGroupName -DiskName $_.name -DiskUpdate $diskUpdateConfig
    }
    else {
        Write-Host "Performance tier for" $_.name "is same as requested" -ForegroundColor Cyan
    }
}
catch {
    Write-Host $Error[0].Exception.Message -ForegroundColor Red;
    Write-Host "Cannot be done for" $_.name -ForegroundColor Red
}
finally{
   $ErrorActionPreference = "Continue"
}
}
