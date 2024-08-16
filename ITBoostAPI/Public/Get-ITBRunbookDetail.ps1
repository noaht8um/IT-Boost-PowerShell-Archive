function Get-ITBRunbookDetail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Uuid')]
        [PSCustomObject[]]$Runbook
    )

    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        foreach ($R in $Runbook) {
            $AllResponses = foreach ($Item in $R.runBookItems.id) {
                $RequestParams = @{
                    Endpoint = "/runbooks/$($R.uuid)/node/$Item"
                    Method   = 'Get'
                    Body     = $Body
                }
                $Data = (Invoke-ITBAPI @RequestParams).itemData
                if (!$Data.Contains('<img ')) {
                    $Data
                    continue
                }
                $Html = $Data | ConvertFrom-HTML
                $Nodes = $Html.SelectNodes('//img')
                foreach ($Node in $Nodes) {
                    $Url = ($Node.Attributes | Where-Object { $_.Name -eq 'src' }).Value
                    $Base64 = 'data:image/png;base64,' + (ConvertUrlToBase64Img -Url $Url)
                    $Node.SetAttributeValue('src', $Base64) | Out-Null
                }
                $Html.WriteTo()
            }
            $AllResponses
        }
    }

}
