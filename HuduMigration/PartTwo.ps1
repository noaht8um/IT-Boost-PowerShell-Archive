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

$AllCreatedItemsDb = "HuduMigration/HuduCreatedItems.xml"

$AllCreatedItems = Import-Clixml $AllCreatedItemsDb

# Get all ITBoost templates
$ITBTemplates = Get-ITBTemplate

# Get all Hudu Companies
$HuduCompanies = Get-HuduCompanies

# Get all Hudu Asset Layouts
$HuduAssetLayouts = Get-HuduAssetLayouts

### Asset Maps ###
$AssetMapFiles = Get-ChildItem "ITBoost API/AssetMaps/"
$AssetMaps = @{}
$AssetMapFiles | ForEach-Object { $AssetMaps[$_.BaseName] = & $_ }

### Assets Take 2 ###
$AllFlexibleAssets = & "ITBoost API/AllFlexibleAssetsParallel.ps1" -Connection $Connection
$AssetsToImport = $AllFlexibleAssets | Where-Object { $_.ITBTemplateName -in $AssetMaps.Keys }

# Documents
$AllArticleDetails = & "ITBoost API/AllArticlesParallel.ps1" -Connection $Connection

# Passwords
$Passwords = & 'ITBoost API/AllPasswordsParallel.ps1' -Connection $Connection

# Attachments
# Combine all ITB Items into one array
$AllITBItems = $AllArticleDetails + $AssetsToImport

$ITBAttachmentDir = "ITBoostAttachments"

$ITBUploadsDir = "ITBoostUploads"

# Get all downloaded attachment UUIDs
$ITBAttachmentUuids = (Get-ChildItem $ITBAttachmentDir).name

$Uploads = foreach ($ITBAttachmentUuid in $ITBAttachmentUuids) {
    # Get ITB item that has attachment attached
    $ITBItem = $AllITBItems | Where-Object { $ITBAttachmentUuid -in $_.attachment.uuid }

    if (!$ITBItem) { continue }

    # Get specific ITB Attachment item
    $ITBAttachment = $ITBItem.attachment | Where-Object { $_.uuid -eq $ITBAttachmentUuid }

    # Get matching Hudu item
    $HuduItem = $AllCreatedItems.GetEnumerator() | ForEach-Object { $_.Value | Where-Object ITBId -EQ $ITBItem.uuid }
    if (!$HuduItem) { continue }

    $Type = 'Article'
    if ($ITBItem.ITBTemplateName) { $Type = $ITBItem.ITBTemplateName }

    $SourceFile = Get-ChildItem (Join-Path $ITBAttachmentDir $ITBAttachmentUuid)

    if ($SourceFile.count -ne 1) {
        Write-Host "Error with $ITBAttachmentUuid"
        continue
    }

    $HuduCompany = $HuduCompanies | Where-Object { $_.id -eq $HuduItem.company_id }

    $CompanyName = ($HuduCompany.name).Split([IO.Path]::GetInvalidFileNameChars()) -join '_' 

    $FolderName = ($HuduItem.name).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

    $DestinationDir = (Join-Path $ITBUploadsDir $CompanyName $FolderName)

    if (!(Test-Path $DestinationDir)) { New-Item -ItemType Directory -Path $DestinationDir }

    if (!(Test-Path (Join-Path $DestinationDir $SourceFile.name))) {
        Copy-Item $SourceFile $DestinationDir
    }

    $ShortcutFile = Join-Path $DestinationDir 'Docs.webloc'

    if (!(Test-Path $ShortcutFile)) {
        New-MacShortCut -Url $HuduItem.url -Path $ShortcutFile
    }

    [PSCustomObject]@{
        Name     = [uri]::UnescapeDataString($ITBAttachment.filename)
        Type     = $Type
        ITBUuid  = $ITBItem.uuid
        HuduName = $HuduItem.name
        HuduUrl  = $HuduItem.url
    }
}

# Create shortcuts
$UploadDirs = Get-ChildItem $ITBUploadsDir | ForEach-Object { Get-ChildItem $_ }
foreach ($Dir in $UploadDirs) {

}
