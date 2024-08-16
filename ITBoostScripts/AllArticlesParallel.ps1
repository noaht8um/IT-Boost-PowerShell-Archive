[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    $Connection
)

$Companies = Get-ITBCompany

$AllArticles = $Companies | ForEach-Object -ThrottleLimit 10 -Parallel {
    Import-Module ITBoostAPI
    Connect-ITBAPI @using:Connection
    $_ | Get-ITBArticle
}

$AllArticleDetails = $AllArticles | ForEach-Object -ThrottleLimit 10 -Parallel {
    Import-Module ITBoostAPI
    Connect-ITBAPI @using:Connection
    $_ | Get-ITBArticleDetail
}

$AllArticleDetails
