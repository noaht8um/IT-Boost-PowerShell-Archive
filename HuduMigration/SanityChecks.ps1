$ITBCompanies = Get-ITBCompany
$RunbookCompanyCounts = foreach ($ITBCompany in $ITBCompanies) {
    $Count = Invoke-ITBAPI -Method Get -Endpoint "/runbooks/company/$($ITBCompany.uuid)/counts"
    [PSCustomObject]@{
        Company     = $ITBCompany.name
        CompanyUuid = $ITBCompany.uuid
        Count       = $Count.count
    }
}

$SOPCompanyCounts = foreach ($ITBCompany in $ITBCompanies) {
    $Count = Invoke-ITBAPI -Method Get -Endpoint "/checklists/company/$($ITBCompany.uuid)/count"
    [PSCustomObject]@{
        Company     = $ITBCompany.name
        CompanyUuid = $ITBCompany.uuid
        Count       = $Count.count
    }
}
