This mail has been sent from an external source

$SubscriptionID = "69d9f5bd-e2c2-4d19-addc-12711ae84e20"
$TennantID  = "3b23a659-5dc8-40dc-87e6-9904135288f5"
$ResourceGroup = "avd-prd-rg-eastus-001"
 
$HostPoolName = "avd-du-prod-hp-eastus-001"
$ComputerName = "VANTAGEVDISP075"
 
$RDPUser = "avdadmin"
$RDPPass = ("Pass@3214567" | ConvertTo-SecureString -AsPlainText -Force) | ConvertFrom-SecureString
 
Get-AzContext
 
Connect-AzureAD
 
 
#region AzWVDHostPool
 
#Get-AzWvdHostPool -ResourceGroupName $ResourceGroup
    Get-AzWvdHostPool -ResourceGroupName $ResourceGroup | Where {$_.Name -eq $HostPoolName}
 
    $Hosts = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName
    
    $User = "naveen.hasanabada"
    $result = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select AssignedUser, Name  | Where {$_.AssignedUser -like "$User*"}
    $result.Name.Split('/')[1]
 
    #####
$HostPoolName = @("avd-du-prod-hp-eastus-001","avd-su-prod-hp-eastus-001","avd-au-prod-hp-eastus-001")
 
function SearchAssignedUser ($UserName)
{
    foreach($hp in $HostPoolName)
    {
        $result = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $hp | Select AssignedUser, Name  | Where {$_.AssignedUser -like "*$UserName*"}
        
        If($result -ne "" -and $result -ne $null)
        {
            Write-Host "HP: $hp" -ForegroundColor Cyan
            Write-Host $result.AssignedUser
            Write-Host $result.Name.Split('/')[1] -ForegroundColor Yellow
            Write-Host ""
        }
    }
}
 
SearchAssignedUser("holden")
SearchAssignedUser("sachs")    
SearchAssignedUser("hathaw")
 
    #####
    $result = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select AssignedUser, Name  | Where {$_.AssignedUser -like "$User*"}
    $result.Name.Split('/')[1]
 
 
    #How to assign user to the machine
    Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select AssignedUser, Name | Out-GridView
    $upn = (Get-AzADUser | Where {$_.Mail -eq andrzej.demski@vantagerisk.com}).UserPrincipalName
 
    Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName -Name "VANTAGEVDID0009" -AssignedUser $upn
 
    Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName -Name "VANTAGEVDID0009" -AssignedUser "" -Confirm: $false -force
    
 
    $result.GetType()
 
    $res = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select-Object AssignedUser, Name 
 
    $res = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | % {New-Object PSObject -Property @{"User" =$_.AssignedUser; "Host"= $_.Name.Split('/')[1]}} | Out-GridView
 
   
 
#endregion
 
#region StartVM   
 
#$res = Get-AzVM -ResourceGroupName $ResourceGroup -Status | select Name, PowerState | Where {$_.Name -eq $hostToStart}
 
#Get Computer status and if deallocated then start VM
 
    $res = Get-AzVM -Name $ComputerName -Status
 
    If($res.PowerState -eq "VM deallocated")
    {
       #Start VM
       Write-host "Starting machine"
       $res = Start-AzVM -ResourceGroupName $ResourceGroup -Name $ComputerName 
       $VmStatus = $res.Status
       
    }
    elseif($res.PowerState -eq "VM running")
    {
       Write-Host "VM is running"
       $VmStatus = "Succeeded"
    }
 
 
    If($VmStatus -eq "Succeeded")
    {
        # Get Private IP Address
        $Comp_nic = Get-AzNetworkInterface -Name "$ComputerName-nic" | select IpConfigurations
        $PrivateIpAddress = $Comp_nic.IpConfigurations.PrivateIpAddress
 
 
        #Create RDP File
        $RDPString = "full address:s:" + $PrivateIpAddress + ":3389
prompt for credentials:i:0
administrative session:i:1
username:s:$RDPUser
password 51:b:$RDPPass
"
        $RDPString -f $ComputerName | Out-File -FilePath "C:\$ComputerName.rdp"
 
        reg add "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client" /v "AuthenticationLevelOverride" /t "REG_DWORD" /d 0 /f #Skip Cert warning
        mstsc "C:\$ComputerName.rdp"
    }
   
#endregion
 
 
#region Remove VM, nic, Disk and user from hostpool
 
$HostPoolName = "avd-su-test-hp-eastus-001"
 
[System.Collections.ArrayList]$res = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | % {New-Object PSObject -Property @{"User" =$_.AssignedUser; "Host"= $_.Name.Split('/')[1]}}
 
  [System.Collections.ArrayList]$res2 = @{}
 
foreach($item in $res)
{
    if(($item.User -like "*lapinski*") -or ($item.User -like "*boguszewski*") -or ($item.User -like "*demski*") -or ($item.User -like "*Obrien*") -or ($item.User -like "*dey*"))
    {
        Write-Host "znalazlem"
    }
    else
    {
        Write-Host "dodano"
        $res2.Add($item)
    }
 
}
 
$CM = "VANTAGEVDID0014"
 
foreach($item in $res2)
{
$CM = $item.Host
 
    #Get-AzVM -Name $CM
    #Get-AzNetworkInterface -Name "$CM-nic"
    #Get-AzDisk -DiskName $CM
 
    Remove-AzVM -ResourceGroupName $ResourceGroup -Name $CM -Force
    Remove-AzNetworkInterface -ResourceGroupName $ResourceGroup -Name "$CM-nic" -Force
    Remove-AzDisk -ResourceGroupName $ResourceGroup -DiskName $CM -Force
    
 
   $Name = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select Name  | Where {$_.Name -like "*$CM"}
 
   Remove-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName -Name $CM -Force
 
 
Write-Host "Maszyna usunięta"
}
 
#endregion
 
 
#region  Add Devices to Application Group
 
$AppGroupName = "AVD_AzureDataStudio_prod_devices"
$GroupID = ""
$ObjectDeviceID = ""
$UserListFile = "C:\temp\UserList.csv"
$HostPoolName = "avd-au-prod-hp-eastus-001"
 
$ContentFile = Get-Content -Path $UserListFile
$GroupID = (Get-AzureADGroup -SearchString $AppGroupName).ObjectID
 
#check user assigned
foreach($item in $ContentFile)
{
    Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select AssignedUser, Name  | Where {$_.AssignedUser -like "$item*"}
}
 
 
foreach ($item in $ContentFile)
{
    $DeviceName = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select AssignedUser, Name  | Where {$_.AssignedUser -like "$item*"}
    
    If(!($DeviceName))
    {
        Write-Host "User $item nie ma przypisanej maszyny"
    }
    else
    {
        $DeviceName = $DeviceName.Name.Split('/')[1]
 
        $ObjectDeviceID = (Get-AzureADDevice -SearchString $DeviceName).ObjectId
 
        If(!(Get-AzureADGroupMember -ObjectId $GroupID | Where {$_.ObjectId -eq $ObjectDeviceID}))
        {
            Add-AzureADGroupMember -ObjectId $GroupID -RefObjectId $ObjectDeviceID
            Write-Host "Dodano maszynę: $DeviceName"
        }
        else
        {
            Write-host "Maszyna $DeviceName istnieje już w tej grupie"
        }
    }
}
 
 
#endregion
 
 
#region
 
 
#endregion 
 
 
Best regards,
Michal
 
This email and any attachments are confidential and may contain trade secret and/or privileged material. If you are not the intended recipient of this information, do not review, re-transmit, disclose, disseminate, use, or take any action in reliance upon, this information. If you have received this message in error, please advise the sender immediately by reply email and delete this message. 
