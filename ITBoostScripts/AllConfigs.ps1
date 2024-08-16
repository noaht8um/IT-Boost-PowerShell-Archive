$Connection = @{
    XApiKey  = Read-Host -AsSecureString -Prompt 'XApiKey'
    ApiToken = Read-Host -AsSecureString -Prompt 'ApiToken'
}
Import-Module ITBoostAPI
Connect-ITBAPI @Connection
$AllConfigurations = Get-ITBCompany | ForEach-Object -ThrottleLimit 5 -Parallel {
    Import-Module ITBoostAPI
    Connect-ITBAPI @using:Connection
    Get-ITBConfiguration $_
}

