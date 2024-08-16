function Get-ITBRunbook {
    [CmdletBinding(DefaultParameterSetName = 'Company')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Company', ValueFromPipelineByPropertyName = $true)]
        [Alias('Uuid')]
        [string[]]$CompanyUuid,

        [Parameter(Mandatory = $true, ParameterSetName = 'Global')]
        [switch]$Global
    )

    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        if ($Global) {
            $RequestParams['Endpoint'] = '/runbooks/global'
            return Invoke-ITBAPI @RequestParams
        }

        foreach ($C in $CompanyUuid) {
            $RequestParams['Endpoint'] = "/runbooks/company/$C"
            Invoke-ITBAPI @RequestParams
        }
    }
}