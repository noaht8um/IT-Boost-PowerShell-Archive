function Get-ITBPasswordDetails {
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
            $RequestParams['Body'] = @{companyId = $P.companyUuid }
            $RequestParams['Endpoint'] = "/passwords/$($Password.uuid)"
            Invoke-ITBAPI @RequestParams
        }
    }
}
