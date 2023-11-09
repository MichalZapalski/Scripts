Connect-AzAccount 

Set-AzContext -Subscription "ets-wrkp-avd-001"
$ctx=New-AzStorageContext -StorageAccountName "etsstavdfslgx01" -StorageAccountKey "p7/UyYDZb2ypNonigRwNwnV+2YWDfRBY2pIRrkDq/YhdEmbHMs9MhLJNqvQeMPW1ORyP/lCTVtE2ArnPPvswmA==" 

#replace user ID
Get-AzStorageFileHandle -ShareName "capfslogixprofilecontainer01" -Path "capfslogixprofile01/tdey" -Recursive -Context $ctx