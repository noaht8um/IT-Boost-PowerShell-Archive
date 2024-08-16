$AssetTypesToClear = @(
    @{
        Type = 'Applications'
        Name = 'Application Name'
    }
)

$HuduAssetLayouts = Get-HuduAssetLayouts

foreach ($AssetType in $AssetTypesToClear) {
    Write-Host "Deleting $($AssetType.Type)"
    $AssetLayout = $HuduAssetLayouts | Where-Object { $_.name -eq $AssetType.Type }
    Get-HuduAssets -AssetLayoutId $AssetLayout.id | ForEach-Object { Remove-HuduAsset -Id $_.id -CompanyId $_.company_id } | Out-Null
}

# Delete passwords
Get-HuduPasswords | ForEach-Object { Remove-HuduPassword -Id $_.id } | Out-Null

Remove-Item "HuduMigration/HuduCreatedItems.xml"
$AllCreatedItems = @{}

# Remove Hudu Relations
Get-HuduRelations | ForEach-Object { Remove-HuduRelation -Id $_.id } | Out-Null

# Remove company articles
Get-HuduArticles | Where-Object { $_.company_id } | ForEach-Object { Remove-HuduArticle -Id $_.id } | Out-Null

# Remove websites
Get-HuduWebsites | ForEach-Object { Remove-HuduWebsite -Id $_.id } | Out-Null
