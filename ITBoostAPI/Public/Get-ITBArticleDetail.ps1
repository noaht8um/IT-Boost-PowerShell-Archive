function Get-ITBArticleDetail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Uuid')]
        [string[]]$ArticleUuid
    )

    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        foreach ($U in $ArticleUuid) {
            $RequestParams['Endpoint'] = "/articles/$U"
            Invoke-ITBAPI @RequestParams
        }
    }
}
