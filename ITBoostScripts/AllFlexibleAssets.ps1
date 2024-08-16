$ITBTemplates = Get-ITBTemplate

$ITBCompanies = Get-ITBCompany

$AllFlexibleAssets = foreach ($ITBCompany in $ITBCompanies) {
    foreach ($ITBTemplate in $ITBTemplates) {
        $Body = @{
            templateDataId = $ITBTemplate.uuid
            #conditions = [uri]::EscapeDataString('{"recordStatus":"Complete"}')
            conditions     = '{"recordStatus":"Complete"}'
            sortBy         = 'Application Name'
            order          = 'asc'
        
        }
        Invoke-ITBAPI -Method Get "/templates/company/$($ITBCompany.uuid)/templatesData/$($ITBTemplate.uuid)" -Body $Body        
    }
}
