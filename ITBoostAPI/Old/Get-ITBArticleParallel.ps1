function Get-ITBArticleParallel {
    [CmdletBinding(DefaultParameterSetName = 'Company')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'CompanyParallel')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Company', ValueFromPipeline = $true)]
        [PSCustomObject[]]$Company,

        [Parameter(Mandatory = $true, ParameterSetName = 'Global')]
        [switch]$Global,

        [Parameter(Mandatory = $true, ParameterSetName = 'CompanyParallel')]
        [switch]$Parallel,

        [Parameter(ParameterSetName = 'CompanyParallel')]
        [int32]$ThrottleLimit = 1
    )

    process {
        $RequestParams = @{
            Endpoint = "/articles/company/$($Company.uuid)"
        }

        if ($Global) { $RequestParams['Endpoint'] = '/articles/global' }

        if ($Parallel) {
            return $Company | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel (Get-ITBParallelBlock {
                    $RequestParams = $using:RequestParams
                    $RequestParams.Endpoint = "/articles/company/$($_.uuid)"
                    Invoke-ITBAPI @RequestParams
                }
            )
        }

        return Invoke-ITBAPI @RequestParams
    }
}

