# Connect to ITBoost; save connection for parallel usage
$Connection = @{
    ApiToken = Read-Host -AsSecureString -Prompt 'ApiToken'
    XApiKey  = Read-Host -AsSecureString -Prompt 'XApiKey'
}
Connect-ITBAPI @Connection

# Get ITB Companies
$ITBCompanies = Get-ITBCompany

# Connect to Hudu
Connect-MyHuduAPI

$ProgressPreference = 'SilentlyContinue'

# Import ITB Article to Hudu Article Function: Import-ITBArticleToHudu
. "Hudu/Import/KB/Import-ITBArticleToHudu.ps1"

# Password lookup table
# $PasswordTable = Import-Csv "HuduMigration/PasswordLookup.csv"

# Create shortcut with given link (for macOS)
function New-MacShortCut {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>URL</key>
	<string>$Url</string>
</dict>
</plist>
"@ | Out-File $Path
}

#$AttachmentsPath = "HuduAttachments"

#$AllCreatedItemsDb = "HuduMigration/HuduCreatedItems.csv"
#$AllCreatedItems = [System.Collections.Generic.List[PSCustomObject]]::new()
#$AllCreatedItems = @{}

$AllCreatedItemsDb = "HuduMigration/HuduCreatedItems.xml"
# If the created items DB exists AND there's importable content, import the existing content
if ((Test-Path $AllCreatedItemsDb) -and -not ([String]::IsNullOrWhiteSpace((Import-Clixml $AllCreatedItemsDb)))) {
    $AllCreatedItems = Import-Clixml $AllCreatedItemsDb
} else {
    $AllCreatedItems = @{}
}

# $AllLinkedItemsDb = "HuduMigration/HuduLinkedItems.csv"
# $AllLinkedItems = [System.Collections.Generic.List[PSCustomObject]]::new()

if (!(Test-Path $AttachmentsPath)) { New-Item -ItemType Directory -Path $AttachmentsPath }

$DownloadZip = "XXXXXXXXXXXXXXXXX.zip"
$BackupPath = "ITBoostBackup"
if (!(Test-Path $BackupPath)) { Expand-Archive -Path $DownloadZip -DestinationPath $BackupPath }

# Create folder
$FlexibleAssetPath = "$BackupPath/FlexibleAssets"
if (!(Test-Path $FlexibleAssetPath)) { New-Item -ItemType Directory -Path $FlexibleAssetPath }

# Get all ITBoost templates
$ITBTemplates = Get-ITBTemplate

# Get all Hudu Companies
$HuduCompanies = Get-HuduCompanies

# Get all Hudu Asset Layouts
$HuduAssetLayouts = Get-HuduAssetLayouts

# Move files matching names to Flexible Assets folder
#Get-ChildItem -Path $BackupPath | Where-Object { $_.BaseName -in ($ITBTemplates).ITBTemplateName } | Move-Item -Destination $FlexibleAssetPath

## Generalized Asset import
if (!$AllCreatedItems.ContainsKey('Assets')) {
    $AllCreatedItems['Assets'] = [System.Collections.Generic.List[PSCustomObject]]::new()
}

### Asset Maps ###
$AssetMapFiles = Get-ChildItem "ITBoost API/AssetMaps/"
$AssetMaps = @{}
$AssetMapFiles | ForEach-Object { $AssetMaps[$_.BaseName] = & $_ }

### Assets Take 2 ###
$AllFlexibleAssets = & "ITBoost API/AllFlexibleAssetsParallel.ps1" -Connection $Connection
$AssetsToImport = $AllFlexibleAssets | Where-Object { $_.ITBTemplateName -in $AssetMaps.Keys }

$AllAssets = foreach ($Asset in $AssetsToImport) {
    $AssetType = $Asset.ITBTemplateName
    $AssetMap = $AssetMaps[$AssetType]
    $HuduAssetLayout = $HuduAssetLayouts | Where-Object { $_.Name -eq $AssetType }

    # Don't import already imported assets; based on ITB uuid
    if ($Asset.uuid -in $AllCreatedItems.Assets.ITBId) {
        continue
    }
    
    $HuduCompany = $HuduCompanies | Where-Object { $_.name -eq $Asset.company.name }
    $HuduParams = @{
        AssetLayoutId = $HuduAssetLayout.id
        CompanyId     = $HuduCompany.id
        Name          = ($Asset.formData | Where-Object { $_.fieldName -ceq $AssetMap.AssetNameField }).fieldValue
    }

    $Fields = @{}
    # Iterate over "fields" in the ITB Application that 1) we care about and 2) have data
    foreach ($Prop in ($Asset.formData.fieldName | Where-Object { $_ -in $AssetMap.NameMap.Keys })) {
        $Value = ($Asset.formData | Where-Object { $_.fieldName -ceq $Prop }).fieldValue
        if ($Value) {
            $FieldLabel = $AssetMap.NameMap.$Prop
            $FieldType = ($HuduAssetLayout.fields | Where-Object { $_.label -eq $FieldLabel }).field_type
            if ($FieldType -eq 'RichText') {
                # Remove empty lines and convert to HTML with <p> tags
                $Value = $Value -creplace '(?m)^\s*\r?\n'
                $Value = ($Value -split "`n").ForEach({ "<p>$_</p>" })
                $Value = $Value -join ''
            }
            $Fields[$FieldLabel] = $Value
        }
    }
    if ($Fields) {
        $HuduParams['Fields'] = $Fields
    }

    try {
        # Create Hudu asset and store response
        #$HuduAsset = New-HuduAsset @HuduParams
    } catch {
        Write-Host "Unable to import asset with ITB ID: $($Asset.uuid)"
    }
    
    if ($HuduAsset) {
        # Add ITB ID and Company Name to the response
        $CreatedItem = $HuduAsset.asset | Select-Object *, @{Name = 'ITBId'; Expression = { $Asset.uuid } }
        # Add response to List
        $AllCreatedItems.Assets.Add($CreatedItem)
        $HuduAsset
        continue
    }
    Write-Host 'An error occurred'
}

## Domains
$ITBADDomains = $AllFlexibleAssets | Where-Object { ($_.ITBTemplateName -eq 'Active Directory') -and ($_.'Additional Notes') }
$HuduADDomainAL = $HuduAssetLayouts | Where-Object { $_.name -eq 'Active Directory Domains' }
$HuduADDomains = Get-HuduAssets -AssetLayoutId $HuduADDomainAL.id

$UpdatedDomains = foreach ($ADDomain in $ITBADDomains) {
    # Find matching Hudu AD Domain by domain name
    $HuduMatch = $HuduADDomains | Where-Object { $_.name -eq $ADDomain.'Domain Name' }

    # Exit if no matching domain found
    if (!$HuduMatch) {
        continue
    }

    $Value = $ADDomain.'Additional Notes'
    $Value = $Value -creplace '(?m)^\s*\r?\n'
    $Value = ($Value -split "`n").ForEach({ "<p>$_</p>" })
    $Value = $Value -join ''

    $Fields = @{
        'Additional Notes' = $Value
    }

    $HuduParams = @{
        Fields = $Fields
    }

    Set-HuduAsset -AssetId $HuduMatch.id -Fields $Fields -Name $HuduMatch.name -CompanyId $HuduMatch.company_id -AssetLayoutId $HuduADDomainAL.id
}

# documents
if (!$AllCreatedItems.ContainsKey('Knowledge Base')) {
    $AllCreatedItems['Knowledge Base'] = [System.Collections.Generic.List[PSCustomObject]]::new()
}

$AllArticleDetails = & "ITBoost API/AllArticlesParallel.ps1" -Connection $Connection
$NewArticles = foreach ($Article in $AllArticleDetails) {
    # Don't import already imported passwords; based on ITB ID
    if ($Article.id -in $AllCreatedItems['Knowledge Base'].ITBId) {
        continue
    }

    # Don't import empty articles
    if ($Article.fileContent -eq '') {
        Write-Host "Empty article found: $($Article.ITBRunbookName) | $($Article.uuid)"
        continue
    }

    # Create article
    try {
        # Create Hudu password and store response
        $HuduArticle = $Article | Import-ITBArticleToHudu
    } catch {
        Write-Host "Unable to import article with ITB UUID: $($Article.uuid)"
    }

    if ($HuduArticle) {
        $CreatedItem = $HuduArticle | Select-Object *, @{Name = 'ITBId'; Expression = { $Article.id } }
        # Add response to List
        $AllCreatedItems['Knowledge Base'].Add($CreatedItem)
        $HuduArticle
        continue
    }
    Write-Host "An error occurred with article: $($Article.uuid)"
}

# passwords
# No items can be linked to a password (but PWs can be linked to other items)?
$Passwords = & 'ITBoost API/AllPasswordsParallel.ps1' -Connection $Connection
if (!$AllCreatedItems.ContainsKey('Password')) {
    $AllCreatedItems['Password'] = [System.Collections.Generic.List[PSCustomObject]]::new()
}

$PasswordTypeMap = @{
    # Active Directory
    'Active Directory'                 = 'Active Directory'
}

$NewPasswords = foreach ($Password in $Passwords) {
    # Don't import already imported passwords; based on ITB ID
    if ($Password.uuid -in $AllCreatedItems.Passwords.ITBId) {
        continue
    }
    $ITBCompany = $ITBCompanies | Where-Object { $_.uuid -eq $Password.companyUuid }
    $HuduCompany = $HuduCompanies | Where-Object { $_.name -eq $ITBCompany.name }
    # Leave if there's not a Company AND name AND password
    if (-not(($HuduCompany.Count -eq 1) -and ($Password.passwordName) -and ($Password.password))) {
        continue
    }
    # Build up Hudu password
    $HuduParams = @{
        CompanyId = $HuduCompany.Id
        Name      = $Password.passwordName
        Password  = $Password.password
    }
    # Ignore 'unknown' as username
    if (($Password.userNamePassword) -and ($Password.userNamePassword -ne 'unknown')) {
        $HuduParams['Username'] = $Password.userNamePassword
    }
    # Don't set Password type for 'No Credential Type'
    if (($Password.type) -and ($Password.type -ne 'No Credential Type')) {
        # Use password type map table if found
        if ($Password.type -in $PasswordTypeMap.Keys) {
            $HuduParams['PasswordType'] = $PasswordTypeMap[$Password.type]
        } else {
            $HuduParams['PasswordType'] = $Password.type
        }
    }
    # Add URL if it exists
    if ($Password.server) {
        $HuduParams['Url'] = $Password.server
    }
    # Description AKA notes
    if ($Password.notes) {
        $HuduParams['Description'] = $Password.notes
    }
    try {
        # Create Hudu password and store response
        #$HuduPassword = New-HuduPassword @HuduParams
    } catch {
        Write-Host "Unable to import password with ITB ID: $($Password.id)"
    }

    if ($HuduPassword) {
        # Add ITB ID and Company Name to the response
        $CreatedItem = $HuduPassword.asset_password | Select-Object *, @{Name = 'ITBId'; Expression = { $Password.uuid } }, @{Name = 'company_name'; Expression = { $HuduCompany.name } }
        # Add response to List
        $AllCreatedItems.Password.Add($CreatedItem)
        $HuduPassword
        continue
    }
    Write-Host 'An error occurred'
}
#### END PASSWORDS ####

### Websites AKA SSL Certs/Domains
#Domains
if (!$AllCreatedItems.ContainsKey('Domain Tracker')) {
    $AllCreatedItems['Domain Tracker'] = [System.Collections.Generic.List[PSCustomObject]]::new()
}

$Domains = $ITBCompanies | ForEach-Object {
    $Organization = $_.name
    Invoke-ITBAPI -Method Get "/trackers/company/$($_.uuid)/whois" `
    | Select-Object *, @{Name = 'organization'; Expression = { $Organization } }
}

$NewDomains = foreach ($Domain in $Domains) {
    $WebsiteName = 'http://' + $Domain.domainName
    # Don't import already imported Domains; based on ITB ID; also don't import duplicate
    if (($Domain.uuid -in $AllCreatedItems['Domain Tracker'].ITBId) -or ($WebsiteName -in $AllCreatedItems['Domain Tracker'].name)) {
        continue
    }

    $HuduCompany = $HuduCompanies.Where({ $_.name -eq $Domain.organization })
    # Leave if there's not a Company AND name AND domain name
    if (-not(($HuduCompany.Count -eq 1) -and ($Domain.domainName))) {
        continue
    }

    # Build up Hudu Domain
    $HuduDomainParams = @{
        CompanyId  = $HuduCompany.Id
        Name       = $WebsiteName
        DisableSSL = $true
        Paused     = $true
    }

    try {
        # Create Hudu domain and store response
        $HuduDomain = New-HuduWebsite @HuduDomainParams
    } catch {
        Write-Host "Unable to import domain with ITB ID: $($Domain.uuid)"
    }

    if ($HuduDomain) {
        # Add ITB ID and Company Name to the response
        $CreatedItem = $HuduDomain | Select-Object *, @{Name = 'ITBId'; Expression = { $Domain.uuid } }
        # Add response to List
        $AllCreatedItems['Domain Tracker'].Add($CreatedItem)
        $HuduDomain
        continue
    }
    Write-Host 'An error occurred'
}

#SSL Certs
if (!$AllCreatedItems.ContainsKey('Domain Tracker')) {
    $AllCreatedItems['Domain Tracker'] = [System.Collections.Generic.List[PSCustomObject]]::new()
}

$Certs = $ITBCompanies | ForEach-Object {
    $Organization = $_.name
    Invoke-ITBAPI -Method Get "/trackers/company/$($_.uuid)/ssl" `
    | Select-Object *, @{Name = 'organization'; Expression = { $Organization } }
}

$NewCerts = foreach ($Cert in $Certs) {
    $WebsiteName = 'https://' + $Cert.website
    # Don't import already imported Certs; based on ITB ID; also don't import duplicate
    if (($Cert.uuid -in $AllCreatedItems['Domain Tracker'].ITBId) -or ($WebsiteName -in $AllCreatedItems['Domain Tracker'].name)) {
        continue
    }

    $HuduCompany = $HuduCompanies.Where({ $_.name -eq $Cert.organization })
    # Leave if there's not a Company AND name AND domain name
    if (-not(($HuduCompany.Count -eq 1) -and ($Cert.website))) {
        continue
    }

    # Build up Hudu Cert
    $HuduCertParams = @{
        CompanyId    = $HuduCompany.Id
        Name         = $WebsiteName
        DisableDNS   = $true
        DisableWhois = $true
    }

    try {
        # Create Hudu domain and store response
        $HuduCert = New-HuduWebsite @HuduCertParams
    } catch {
        Write-Host "Unable to import cert with ITB ID: $($Cert.uuid)"
    }

    if ($HuduCert) {
        # Add ITB ID and Company Name to the response
        $CreatedItem = $HuduCert | Select-Object *, @{Name = 'ITBId'; Expression = { $Domain.uuid } }
        # Add response to List
        $AllCreatedItems['Domain Tracker'].Add($CreatedItem)
        $HuduCert
        continue
    }
    Write-Host 'An error occurred'
}
# RB - same as docs

# ssl-certificates - see domains

# Add linkedItems to "db"

# LinkedItems
# $ExistingLinkedItems = Import-Csv $AllLinkedItemsDb
# 
# foreach ($Item in $AllLinkedItems) {
#     $Matched = $ExistingLinkedItems | Where-Object { ($_.SourceAssetId -eq $Item.SourceAssetId) -and ($_.LinkedAssetId -eq $Item.LinkedAssetId) }
#     if (!$Matched) {
#         $Item | Export-Csv $AllLinkedItemsDb -Append
#     }
# }

# $CreatedItemTable = @{
#     Article         = 'Articles'
#     Password        = 'Passwords'
#     'Microsoft 365' = 'Assets'
# }

# Create Links/Relations
$AllLinks = [System.Collections.Generic.List[PSCustomObject]]::new()

# Passwords
foreach ($Password in ($Passwords | Where-Object { $_.linkedItem })) {
    foreach ($LinkedItem in $Password.linkedItem) {
        $SourceUuid = $Password.uuid
        $LinkedUuid = $LinkedItem.relatedAssetId
        $Duplicate = $AllLinks | Where-Object {
            (($_.SourceUuid -eq $SourceUuid) -and ($_.LinkedUuid -eq $LinkedUuid)) -or
            (($_.SourceUuid -eq $LinkedUuid) -and ($_.LinkedUuid -eq $SourceUuid))
        }
        # Skip dupes
        if ($Duplicate) {
            Write-Host "Skipping dupe $($Password.passwordName)"
            continue
        }
        $NewLink = [PSCustomObject]@{
            SourceType = 'Password'
            SourceName = $Password.passwordName
            SourceUuid = $SourceUuid
            LinkedType = $LinkedItem.relatedAsset
            LinkedName = $LinkedItem.relatedAssetName
            LinkedUuid = $LinkedUuid
        }
        $AllLinks.Add($NewLink)
    }
}

# Articles
foreach ($Article in ($AllArticleDetails | Where-Object { $_.linkedItem })) {
    foreach ($LinkedItem in $Article.linkedItem) {
        $SourceUuid = $Article.uuid
        $LinkedUuid = $LinkedItem.relatedAssetId
        $Duplicate = $AllLinks | Where-Object {
            (($_.SourceUuid -eq $SourceUuid) -and ($_.LinkedUuid -eq $LinkedUuid)) -or
            (($_.SourceUuid -eq $LinkedUuid) -and ($_.LinkedUuid -eq $SourceUuid))
        }
        # Skip dupes
        if ($Duplicate) {
            Write-Host "Skipping dupe $($Article.ITBRunBookName)"
            continue
        }
        $NewLink = [PSCustomObject]@{
            SourceType = 'Knowledge Base'
            SourceName = $Article.ITBRunBookName
            SourceUuid = $SourceUuid
            LinkedType = $LinkedItem.relatedAsset
            LinkedName = $LinkedItem.relatedAssetName
            LinkedUuid = $LinkedUuid
        }
        $AllLinks.Add($NewLink)
    }
}

# Assets
foreach ($Asset in ($AllFlexibleAssets | Where-Object { $_.linkedItem })) {
    foreach ($LinkedItem in $Asset.linkedItem) {
        $AssetType = $Asset.ITBTemplateName
        $AssetMap = $AssetMaps[$AssetType]
        $AssetName = ($Asset.formData | Where-Object { $_.fieldName -ceq $AssetMap.AssetNameField }).fieldValue

        $SourceUuid = $Asset.uuid
        $LinkedUuid = $LinkedItem.relatedAssetId
        $Duplicate = $AllLinks | Where-Object {
            (($_.SourceUuid -eq $SourceUuid) -and ($_.LinkedUuid -eq $LinkedUuid)) -or
            (($_.SourceUuid -eq $LinkedUuid) -and ($_.LinkedUuid -eq $SourceUuid))
        }
        # Skip dupes
        if ($Duplicate) {
            Write-Host "Skipping dupe $AssetName"
            continue
        }
        $NewLink = [PSCustomObject]@{
            SourceType = $Asset.ITBTemplateName
            SourceName = $AssetName
            SourceUuid = $SourceUuid
            LinkedType = $LinkedItem.relatedAsset
            LinkedName = $LinkedItem.relatedAssetName
            LinkedUuid = $LinkedUuid
        }
        $AllLinks.Add($NewLink)
    }
}

$LinkMap = @{
    'Knowledge Base' = 'Article'
    'Assets'         = 'Asset'
    'Password'       = 'AssetPassword'
    'Domain Tracker' = 'Website'
}

$LinkTypes = @(
    'Domain Tracker'
    'Knowledge Base'
    'Password'
)

### Linker
if (!$AllCreatedItems.ContainsKey('Relations')) {
    $AllCreatedItems['Relations'] = [System.Collections.Generic.List[PSCustomObject]]::new()
}

$AllRelations = foreach ($Link in $AllLinks) {
    # Source
    if ($Link.SourceType -in $LinkTypes) {
        $SourceType = $Link.SourceType
    } else {
        $SourceType = 'Assets'
    }
    $HuduFromable = $AllCreatedItems[$SourceType] | Where-Object { $_.ITBId -eq $Link.SourceUuid }

    #Linked
    if ($Link.LinkedType -in $LinkTypes) {
        $LinkedType = $Link.LinkedType
    } else {
        $LinkedType = 'Assets'
    }
    $HuduToable = $AllCreatedItems[$LinkedType] | Where-Object { $_.ITBId -eq $Link.LinkedUuid }

    ## Create
    if ($SourceType -eq 'Assets') {
        $FromableType = 'Asset'
    } else {
        $FromableType = $LinkMap.($Link.SourceType)
    }

    if ($LinkedType -eq 'Assets') {
        $ToableType = 'Asset'
    } else {
        $ToableType = $LinkMap.($Link.LinkedType)
    }

    $HuduParams = @{
        FromableType = $FromableType
        FromableID   = $HuduFromable.id
        ToableType   = $ToableType
        ToableID     = $HuduToable.id
    }
    
    try {
        # Create Hudu relation and store response
        #$HuduRelation = New-HuduRelation @HuduParams
    } catch {
        Write-Host "Unable to create Hudu relation with Fromable ID: $($HuduFromable.id) and Toable ID: $($HuduToable.id)"
    }
    
    if ($HuduRelation) {
        $CreatedItem = $HuduRelation.relation
        # Add response to List
        $AllCreatedItems.Relations.Add($CreatedItem)
        $HuduRelation
        continue
    }
    Write-Host 'An error occurred'
}

# Save Created Items to disk
#$AllCreatedItems | Export-Csv -Append $AllCreatedItemsDb
$AllCreatedItems | Export-Clixml $AllCreatedItemsDb

# Relations validation



### Attachments

# Passwords
$Passwords.attachment

# Assets
$AllFlexibleAssets.attachment

# Articles
$AllArticleDetails.attachment
