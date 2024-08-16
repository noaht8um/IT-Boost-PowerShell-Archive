# Connect to ITBoost; save connection for parallel usage
$Connection = @{
    ApiToken = Read-Host -AsSecureString -Prompt 'ApiToken'
    XApiKey  = Read-Host -AsSecureString -Prompt 'XApiKey'
}
Connect-ITBAPI @Connection

# Get ITB Companies
$ITBCompanies = Get-ITBCompany

$ITBTemplates = Get-ITBTemplate

$SitePhotos = foreach ($ITBCompany in $ITBCompanies) {
    Get-ITBFlexibleAsset -TemplateId $ITBTemplate.uuid -CompanyUuid $ITBCompany.uuid | Select-Object *,
    @{n = 'companyUuid'; e = { $ITBCompany.uuid } },
    @{n = 'companyName'; e = { $ITBCompany.name } }
}

if (!(Test-Path $AttachmentsPath)) { New-Item -ItemType Directory -Path $AttachmentsPath }
