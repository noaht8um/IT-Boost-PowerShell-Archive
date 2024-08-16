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
        
        $Body = @{
            templateDataId = $ITBTemplate.uuid
            conditions     = '{"recordStatus":"Complete"}'
            sortBy         = 'Application Name'
            order          = 'asc'      
        }
        
        Invoke-ITBAPI -Method Get -Endpoint "/templates/company/$($ITBCompany.uuid)/templatesData/$($ITBTemplate.uuid)" -Body $Body | Select-Object *,
        @{Name = 'companyUuid'; Expression = { $ITBCompany.uuid } },
        @{Name = 'companyName'; Expression = { $ITBCompany.name } }
    }
}

$AllFlexibleAssets
