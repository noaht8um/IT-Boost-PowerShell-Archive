function Get-ITBArticle {
    [CmdletBinding(DefaultParameterSetName = 'Company')]
    param (
        [Parameter(ParameterSetName = 'CompanyWithDetail', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = 'Company', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
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
            $RequestParams['Endpoint'] = '/articles/global'
            return Invoke-ITBAPI @RequestParams
        }

        foreach ($C in $CompanyUuid) {
            $RequestParams['Endpoint'] = "/articles/company/$C"
            Invoke-ITBAPI @RequestParams
        }
    }
}