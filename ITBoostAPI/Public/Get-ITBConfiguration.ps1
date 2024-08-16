function Get-ITBConfiguration {
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
            $RequestParams['Endpoint'] = "/configurations/company/$C"
            (Invoke-ITBAPI @RequestParams).ToString().Replace('name', '_name') | ConvertFrom-Json
        }
    }
}