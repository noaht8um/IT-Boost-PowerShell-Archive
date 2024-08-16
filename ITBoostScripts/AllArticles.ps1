[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    $Connection
)

$Companies = Get-ITBCompany

$AllArticles = foreach ($Company in $Companies) {
    Get-ITBArticle -CompanyUuid $Company.uuid
}

$AllArticleDetails = foreach ($Article in $AllArticles) {
    Get-ITBArticleDetail -ArticleUuid $Article.uuid
}

$AllArticleDetails
