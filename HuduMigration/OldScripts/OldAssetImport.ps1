
$AssetTypesToImport = @(
    @{
        Type = 'Applications'
        Name = 'Application Name'
    }
)

foreach ($AssetType in $AssetTypesToImport) {
    $Assets = Import-Csv "$FlexibleAssetPath/$($AssetType.Type).csv"
    $AssetMap = & "ITBoost API/AssetMaps/$($AssetType.Type).ps1"
    $HuduAssetLayout = $HuduAssetLayouts | Where-Object { $_.Name -eq $AssetType.Type }

    # Start by creating applications without links
    $UniqueAssets = $Assets | Group-Object id | ForEach-Object { $_.Group | Select-Object -First 1 }
    $AllAssets = foreach ($Asset in $UniqueAssets) {
        # Don't import already imported assets; based on ITB ID
        if ($Asset.id -in $AllCreatedItems.Assets.ITBId) {
            continue
        }
    
        $HuduCompany = $HuduCompanies | Where-Object { $_.name -eq $Asset.organization }
        $HuduAssetParams = @{
            AssetLayoutId = $HuduAssetLayout.id
            CompanyId     = $HuduCompany.id
            Name          = $Asset.($AssetType.Name)
        }

        $Fields = @{}
        # Iterate over "fields" in the ITB Application that 1) we care about and 2) have data
        foreach ($Prop in ($Asset.psobject.properties.Name | Where-Object { $_ -in $AssetMap.Keys })) {
            $Value = $Asset.$Prop
            if ($Value) {
                $FieldLabel = $AssetMap.$Prop
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
            $HuduAssetParams['Fields'] = $Fields
        }

        try {
            # Create Hudu asset and store response
            $HuduAsset = New-HuduAsset @HuduAssetParams
        } catch {
            Write-Host "Unable to import asset with ITB ID: $($Asset.resource_id)"
        }
    
        if ($HuduAsset) {
            # Add ITB ID and Company Name to the response
            $CreatedItem = $HuduAsset.asset | Select-Object *, @{Name = 'ITBId'; Expression = { $Asset.id } }
            # Add response to List
            $AllCreatedItems.Assets.Add($CreatedItem)
            $HuduAsset
            continue
        }
        Write-Host 'An error occurred'
    }
}

#$ADDomains = Import-Csv (Get-ChildItem $FlexibleAssetPath | Where-Object { $_.BaseName -eq 'Active Directory' })

#$ADDomains | Where-Object { ($_.'Domain name' -notin $Domains.name) -and ($_.'Additional Notes') }
#$UniqueDomains = $ADDomains | Where-Object { $_.'Domain name' -notin $Domains.name } `
#| Group-Object 'Domain Name' | ForEach-Object { $_.Group | Select-Object -First 1 } `

#$ADNotes = $ADDomains | Where-Object 'Additional Notes' `
#| Select-Object organization, 'Domain Name', 'Additional Notes' `
#| Sort-Object 'Additional Notes' -Unique `
#| Sort-Object organization, 'Domain Name'


# Create LinkedItem Table
#if ($Article.linkedItem) {
#    $LinkedItems = $Article.linkedItem
#    foreach ($LinkedItem in $LinkedItems) {
#        # Skip existing links
#        $ExistingLink = $AllLinkedItems | Where-Object { ($_.SourceAssetId -eq $Article.uuid) -and ($_.LinkedAssetId -eq $LinkedItem.relatedAssetId) }
#        if ($ExistingLink) {
#            continue
#        }
#
#        $LinkedItemEntry = [PSCustomObject]@{
#            SourceAssetType = 'Article'
#            SourceAssetName = $Article.ITBRunBookName
#            SourceAssetId   = $Article.uuid
#            LinkedAssetType = $LinkedItem.relatedAsset
#            LinkedAssetName = $LinkedItem.relatedAssetName
#            LinkedAssetId   = $LinkedItem.relatedAssetId
#        }
#        $AllLinkedItems.Add($LinkedItemEntry)
#    }
#}

## Download attachments
#if ($Article.attachment) {
#    $CompanyName = ($Article.company.name).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
#    # ORG / COMPANY / articles / ARTICLE ID
#    $Attachments = $Article.attachment
#    foreach ($Attachment in $Attachments) {
#        $Dir = Join-Path $AttachmentsPath $CompanyName $Article.id
#        $NewName = [uri]::UnescapeDataString($Attachment.filename)
#        $FullPath = Join-Path $Dir $NewName
#        # Create Article path if it doesn't exist
#        if (!(Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir }
#        # Get attachment if it doesn't exist
#        if (!(Test-Path $FullPath)) {
#            $Url = Get-ITBSignedUrl ($Attachment.path + $Attachment.filename)
#            Invoke-RestMethod $Url -OutFile $FullPath
#        }
#    }
#}


$ArticleLinks = $AllLinkedItems | Where-Object { ($_.SourceAssetType -eq 'Article') -and ($_.LinkedAssetType -eq 'Password') }
foreach ($Link in $ArticleLinks) {
    $SourceType = $CreatedItemTable.($Link.SourceAssetType)
    $LinkedType = $CreatedItemTable.($Link.LinkedAssetType)
    $LinkedAssetId = $Link.LinkedAssetId
    # Password special lookup
    if (($LinkedType -eq 'Password') -and ($LinkedAssetId -match '^[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}$')) {
        #DocId                    OnlineUuid
        $DocId = ($PasswordTable | Where-Object { $_.OnlineUuid -eq $Link.LinkedAssetId }).DocId
        if ($DocId) {
            $LinkedAssetId = $DocId
        }
    }
    $Fromable = $AllCreatedItems.($SourceType) | Where-Object { $_.ITBId -eq $Link.SourceAssetId }
    $Toable = $AllCreatedItems.($LinkedType) | Where-Object { $_.ITBId -eq $LinkedAssetId }

    $ToableType = 'AssetPassword'

    # Create relation
    New-HuduRelation -FromableType $Fromable.object_type -FromableID $Fromable.id -ToableType $ToableType -ToableID $Toable.id
    # Create inverse relation; guess it's not needed?
    #New-HuduRelation -FromableType AssetPassword -FromableId 670 -ToableType Article -ToableId 220 -ISInverse True
}

$PasswordLinkData = Import-Csv "$BackupPath/passwords.csv" | Where-Object { ($_.resource_type) -or ($_.resource_id) }

$HuduAssetsWithCards = Get-HuduAssets | Where-Object { $_.cards }

$ITBConfigurations = $ITBCompanies | Get-ITBConfiguration

$RelationMap = @{
    'Applications' = 'Applications'
}

foreach ($Item in $PasswordLinkData) {
    # Special lookup for Configuration type
    if ($Item.resource_type -eq 'Configuration') {
        $ITBConfigMatch = $ITBConfigurations | Where-Object { $_.uuid -eq $Item.resource_id }
        if (!$ITBConfigMatch) {
            continue
        }
        $HuduAsset = $HuduAssetsWithCards | Where-Object {
            ($ITBConfigMatch.id -in $_.cards.sync_id) -and ($_.cards.sync_type -eq 'configuration')
        }
    }


    #$Fromable = $AllCreatedItems.($SourceType) | Where-Object { $_.ITBId -eq $Link.SourceAssetId }
    #$Toable = $AllCreatedItems.($LinkedType) | Where-Object { $_.ITBId -eq $LinkedAssetId }
}

# Get all assets
foreach ($Type in $AssetMaps.Keys) { Get-HuduAssets -AssetLayoutId ($HuduAssetLayouts | Where-Object { $_.name -eq $Type }).id }
