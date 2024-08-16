function Read-ITBArticle {
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
        foreach ($Uuid in $ArticleUuid) {
            $RequestParams['Endpoint'] = "/articles/$Uuid"
            Invoke-ITBAPI @RequestParams
        }
    }
}
