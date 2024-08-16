function Get-ITBLocation {
    [CmdletBinding(DefaultParameterSetName = 'Company')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Company', ValueFromPipelineByPropertyName = $true)]
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
            $RequestParams['Endpoint'] = "/locations/company/$C"
            Invoke-ITBAPI @RequestParams
        }
    }
}