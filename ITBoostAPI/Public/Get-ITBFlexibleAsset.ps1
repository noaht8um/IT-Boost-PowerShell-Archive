function Get-ITBFlexibleAsset {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Uuid')]
        [string[]]$CompanyUuid,

        [Parameter(Mandatory = $true)]
        [string]$TemplateId
    )

    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        foreach ($C in $CompanyUuid) {
            $RequestParams['Endpoint'] = "/templates/company/$CompanyUuid/templatesData/$TemplateId"
            $RequestParams['Body'] = @{templateDataId = $TemplateId }
            Invoke-ITBAPI @RequestParams
        }
    }
}
