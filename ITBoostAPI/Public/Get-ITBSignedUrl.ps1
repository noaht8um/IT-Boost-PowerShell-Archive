function Get-ITBSignedUrl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Path')]
        [string[]]$ContentPath
    )

    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        foreach ($P in $ContentPath) {
            $RequestParams['Endpoint'] = '/users/getSignedUrl'
            $RequestParams['Body'] = @{contentPath = $P }
            (Invoke-ITBAPI @RequestParams).signedUrl
        }
    }
}
