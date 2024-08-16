$Companies = Get-ITBCompany

$CurrentCompany = 0
$Export = foreach ($Company in $Companies) {
    # Progress Bar
    $PercentComplete = [int](($CurrentCompany / $Companies.Count) * 100)
    Write-Progress -Activity 'Working through clients' -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete -Id 1
    $CurrentCompany++
    
    $Passwords = $Passwords = Get-ITBPassword -Company $Company

    $CurrentPassword = 0
    foreach ($Password in $Passwords) {
        # Progress Bar
        $PercentComplete = [int](($CurrentPassword / $Passwords.Count) * 100)
        Write-Progress -Activity "Pulling Passwords for $($Company.name)" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete -ParentId 1
        $CurrentPassword++

        $Permissions = if ($Password.userPermission) {
            $Password.userPermission.fullName -join '|'
        } else {
            'all'
        }
        $Value = try { Read-ITBPassword -Password $Password } catch {}
        [PSCustomObject]@{
            Company        = $Company.name
            Name           = $Password.passwordName
            Username       = $Password.userNamePassword
            Value          = $Value
            URL            = $Password.server
            Type           = $Password.type
            Notes          = $Password.notes
            Permissions    = $Permissions
            ITBLastUpdated = $Password.ITBLastUpdated
        }
    }
}

$Export
