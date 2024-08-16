function ITBToHuduGlobalRunbooks {
    $ITBRunbooks = Get-ITBRunbook -Global | Sort-Object ITBRunBookName
    $HuduFolderName = 'Runbooks'
    $HuduFolder = Get-HuduFolders | Where-Object { $_.name -eq $HuduFolderName }
    foreach ($ITBRunbook in $ITBRunbooks) {
        $HuduArticleContent = ($ITBRunbook | Get-ITBRunbookDetail).ForEach({ $_.ToString() })
        if (-not($HuduArticleContent)) {
            Write-Host "Global Runbook $($ITBRunbook.ITBRunBookName) is blank!"
            continue
        }

        $HuduArticle = @{
            Name     = $ITBRunbook.ITBRunBookName
            Content  = $HuduArticleContent
            FolderId = $HuduFolder.id
        }

        Write-Host "Creating global KB Article $($ITBRunbook.ITBRunBookName)."
        $NewArticle = New-HuduArticle @HuduArticle
    }
}
