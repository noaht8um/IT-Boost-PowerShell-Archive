function Get-ITBPassword {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Uuid')]
        [string[]]$CompanyUuid
    )

    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        foreach ($C in $CompanyUuid) {
            $RequestParams['Endpoint'] = "/passwords/company/$C"
            Invoke-ITBAPI @RequestParams
        }
    }
}