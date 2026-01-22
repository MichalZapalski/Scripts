This mail has been sent from an external source

$SubscriptionID = ""
$TennantID  = ""
$ResourceGroup = ""
 
$HostPoolName = ""
$ComputerName = ""
 
$RDPUser = "Username"
$RDPPass = ("Pass" | ConvertTo-SecureString -AsPlainText -Force) | ConvertFrom-SecureString
 
Get-AzContext
 
Connect-AzureAD
 
 
#region AzWVDHostPool
 
#Get-AzWvdHostPool -ResourceGroupName $ResourceGroup
    Get-AzWvdHostPool -ResourceGroupName $ResourceGroup | Where {$_.Name -eq $HostPoolName}
 
    $Hosts = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName
    
    $User = ""
    $result = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select AssignedUser, Name  | Where {$_.AssignedUser -like "$User*"}
    $result.Name.Split('/')[1]
 
    #####
$HostPoolName = @("","","")
 
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
 
SearchAssignedUser("")
SearchAssignedUser("")    
SearchAssignedUser("")
 
    #####
    $result = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select AssignedUser, Name  | Where {$_.AssignedUser -like "$User*"}
    $result.Name.Split('/')[1]
 
 
    #How to assign user to the machine
    Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | Select AssignedUser, Name | Out-GridView
    $upn = (Get-AzADUser | Where {$_.Mail -eq }).UserPrincipalName
 
    Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName -Name "" -AssignedUser $upn
 
    Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName -Name "" -AssignedUser "" -Confirm: $false -force
    
 
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
 
$HostPoolName = ""
 
[System.Collections.ArrayList]$res = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPoolName | % {New-Object PSObject -Property @{"User" =$_.AssignedUser; "Host"= $_.Name.Split('/')[1]}}
 
  [System.Collections.ArrayList]$res2 = @{}
 
foreach($item in $res)
{
    if(($item.User -like "**") -or ($item.User -like "**") -or ($item.User -like "**") -or ($item.User -like "**") -or ($item.User -like "**"))
    {
        Write-Host "znalazlem"
    }
    else
    {
        Write-Host "dodano"
        $res2.Add($item)
    }
 
}
 
$CM = ""
 
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
$HostPoolName = ""
 
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
