function Import-ITBArticleToHudu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject[]]$Article
    )
    
    begin {
        if (!$HuduCompanies) {
            $HuduCompanies = Get-HuduCompanies
        }
    }

    process {
        foreach ($A in $Article) {
            if (-not($A.fileContent)) {
                Write-Verbose "Article $($A.ITBRunBookName) for client $($A.company.name) is blank!"
                continue
            }

            $HuduCompany = $HuduCompanies.Where({ $_.name -ceq $A.company.name })

            $HuduArticleParams = @{
                Name      = $A.ITBRunBookName
                Content   = $A.fileContent
                CompanyId = $HuduCompany.id
            }

            Write-Verbose "Creating KB Article $($A.ITBRunBookName) for client $($A.company.name)."
            (New-HuduArticle @HuduArticleParams).article
        }
    }
}
