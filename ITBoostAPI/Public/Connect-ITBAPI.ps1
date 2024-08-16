function Connect-ITBAPI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [SecureString]$XApiKey,

        [Parameter(Mandatory = $true)]
        [SecureString]$ApiToken
    )

    $Script:ITBXApiKey = $XApiKey
    $Script:ITBApiToken = $ApiToken
}
