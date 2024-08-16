function Read-ITBPassword {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject[]]$Password
    )

    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        foreach ($P in $Password) {
            $RequestParams['Endpoint'] = "/passwords/company/$($P.companyUuid)/$($P.uuid)/view-password"
            Invoke-ITBAPI @RequestParams
        }
    }
}
