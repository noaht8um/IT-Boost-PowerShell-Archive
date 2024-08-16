[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    $Connection
)

$ITBCompanies = Get-ITBCompany

$AllPasswords = $ITBCompanies | ForEach-Object -ThrottleLimit 10 -Parallel {
    Import-Module ITBoostAPI
    Connect-ITBAPI @using:Connection
    $_ | Get-ITBPassword
}

$AllPasswordDetails = $AllPasswords | ForEach-Object -ThrottleLimit 10 -Parallel {
    Import-Module ITBoostAPI
    Connect-ITBAPI @using:Connection
    $_ | Get-ITBPasswordDetails
}

$AllPasswordDetailsWithValues = $AllPasswordDetails | ForEach-Object -ThrottleLimit 10 -Parallel {
    Import-Module ITBoostAPI
    Connect-ITBAPI @using:Connection
    $_ | Select-Object *, @{Name = 'password'; Expression = { ($_ | Read-ITBPassword).password } }
}

$AllPasswordDetailsWithEverything = $AllPasswordDetailsWithValues | ForEach-Object -ThrottleLimit 10 -Parallel {
    Import-Module ITBoostAPI
    Connect-ITBAPI @using:Connection
    $Attachment = $_ | Get-ITBPasswordAttachment
    if ($Attachment) {
        $_ | Select-Object *, @{Name = 'attachment'; Expression = { $Attachment } }
    } else {
        $_
    }
}


$AllPasswordDetailsWithEverything
