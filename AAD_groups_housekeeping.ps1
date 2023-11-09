# Get all groups with names like "app_avd"
$groups = Get-AzADGroup -Filter "startswith(DisplayName, 'app_avd')"

# Create an empty array to store the results
$results = @()

# Loop through each group
foreach ($group in $groups) {
    # Get all members of the group
    $members = Get-AzureADGroupMember -ObjectId $group.ObjectId

    # Loop through each member
    foreach ($member in $members) {
        # Get the groups that the member is a part of
        $ObjectID = Get-AzureADDevice | $userGroups = Get-AzureADUserMembership -ObjectId $member.ObjectId

        # If the member is part of more than one group, add the user details to the results
        if ($userGroups.Count -gt 1) {
            $user = Get-AzADUser -ObjectId $member.ObjectId
            $userDetails = [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                MemberOfGroups = $userGroups.DisplayName -join ', '
            }
            $results += $userDetails
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "UserGroupMembership.csv" -NoTypeInformation