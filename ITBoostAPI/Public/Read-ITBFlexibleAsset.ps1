function Read-ITBFlexibleAsset {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject[]]$FlexibleAsset,

        [Parameter(Mandatory = $true)]
        [string]$CompanyUuid
    )

    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        foreach ($F in $FlexibleAsset) {
            $RequestParams['Endpoint'] = "/templates/templatesData/$($F.Uuid)"
            $RequestParams['Body'] = @{
                companyId      = $CompanyUuid
                templateDataId = $F.ITBTemplateUuid
            }
            Invoke-ITBAPI @RequestParams
        }
    }
}
