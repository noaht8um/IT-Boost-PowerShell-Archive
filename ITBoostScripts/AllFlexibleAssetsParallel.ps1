[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    $Connection
)

$ITBTemplates = Get-ITBTemplate

$ITBCompanies = Get-ITBCompany

$AllFlexibleAssets = foreach ($ITBCompany in $ITBCompanies) {
    $ITBTemplates | ForEach-Object -ThrottleLimit 10 -Parallel {
        Import-Module ITBoostAPI
        Connect-ITBAPI @using:Connection
        $ITBCompany = $using:ITBCompany
        $ITBTemplate = $_

        $ITBCompany | Get-ITBFlexibleAsset -TemplateId $ITBTemplate.uuid | Select-Object *,
        @{Name = 'companyUuid'; Expression = { $ITBCompany.uuid } },
        @{Name = 'companyName'; Expression = { $ITBCompany.name } }
    }
}

$AllFlexibleAssetDetails = $AllFlexibleAssets | ForEach-Object -ThrottleLimit 10 -Parallel {
    Import-Module ITBoostAPI
    Connect-ITBAPI @using:Connection
    $_ | Read-ITBFlexibleAsset -CompanyUuid $_.companyUuid
}

$AllFlexibleAssetDetails
