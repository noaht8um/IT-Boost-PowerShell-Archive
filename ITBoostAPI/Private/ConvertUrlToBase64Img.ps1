function ConvertUrlToBase64Img {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    $WebClient = New-Object System.Net.WebClient

    $Bytes = $WebClient.DownloadData($Url)

    $Base64 = [convert]::ToBase64String($Bytes)

    return $Base64
}