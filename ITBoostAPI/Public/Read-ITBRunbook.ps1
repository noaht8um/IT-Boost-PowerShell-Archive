function Read-ITBRunbook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Runbook
    )

    $AllResponses = foreach ($Item in $Runbook.runBookItems.id) {
        $RequestParams = @{
            Endpoint = "/runbooks/$($Runbook.uuid)/node/$Item"
            Method   = 'Get'
            Body     = $Body
        }
        $Data = (Invoke-ITBAPI @RequestParams).itemData
        if (-not($Data.Contains('<img '))) {
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

    return $AllResponses
}
