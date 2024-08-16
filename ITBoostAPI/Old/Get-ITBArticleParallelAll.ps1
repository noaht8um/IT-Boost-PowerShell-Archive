function Get-ITBArticleParallelAll {
    [CmdletBinding(DefaultParameterSetName = 'Company')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Company', ValueFromPipeline = $true)]
        [PSCustomObject[]]$Company,

        [Parameter(Mandatory = $true, ParameterSetName = 'Global')]
        [switch]$Global,

        [Parameter(ParameterSetName = 'Company')]
        [int32]$ThrottleLimit = 1
    )

    begin {
        $Body = @{ pageSize = 1000 }
    }

    process {
        $RequestParams = @{
            Method = 'Get'
            Body   = $Body
        }

        if ($Global) { $RequestParams.Endpoint = '/articles/global' }

        $ScriptBlock = Get-ITBParallelBlock {
            $RequestParams = $using:RequestParams
            if (!$RequestParams.Endpoint) {
                $RequestParams.Endpoint = "/articles/company/$($_.uuid)"
            }
            Invoke-ITBAPI @RequestParams
        }

        return $Company | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel $ScriptBlock
    }

}
