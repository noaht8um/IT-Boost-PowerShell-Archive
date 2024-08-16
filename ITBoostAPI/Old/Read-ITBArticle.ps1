function Read-ITBArticle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Article
    )

    $Body = @{
        companyId = $Article.companyUuid
    }

    $RequestParams = @{
        Endpoint = "/articles/$($Article.uuid)"
        Method   = 'Get'
        Body     = $Body
    }

    if ($Article.companyUuid -eq 1) {
        $RequestParams.Remove('Body')
    }

    $Response = Invoke-ITBAPI @RequestParams

    return $Response.fileContent
}
