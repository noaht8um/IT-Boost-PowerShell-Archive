function Invoke-ITBAPI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Post', 'Put')]
        [string]$Method,

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},

        [Parameter(Mandatory = $false)]
        [hashtable]$Body,

        [Parameter(Mandatory = $false)]
        [switch]$Proxy
    )

    $BaseUri = 'https://v4-api-na.itboost.com'

    $Uri = $BaseUri + $Endpoint

    $Headers.Item('token') = 'Bearer ' + ($Script:ITBApiToken | ConvertFrom-SecureString -AsPlainText)
    $Headers.Item('x-api-key') = ($Script:ITBXApiKey | ConvertFrom-SecureString -AsPlainText)

    if ((!$Body) -and ($Method -eq 'Get')) {
        $Body = @{ pageSize = 1000 }
    }
    
    $RequestParams = @{
        URI     = $Uri
        Headers = $Headers
        Method  = $Method
        Body    = $Body
    }

    if ($Proxy) { $RequestParams.Proxy = 'http://127.0.0.1:8080' }

    $Response = Invoke-RestMethod @RequestParams

    return $Response
}
