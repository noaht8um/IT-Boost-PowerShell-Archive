function Get-ITBAttachment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$Attachment
    )

    begin {
        $RootPath = "$env:HOME/Documents/ITBoostAttachments"
        if (!(Test-Path $RootPath)) { New-Item -ItemType Directory -Path $RootPath | Out-Null }
    }

    process {
        foreach ($A in $Attachment) {
            # URL unescape file name and then get rid of incompatible characters
            $FileName = ([uri]::UnescapeDataString($A.filename)).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            # Path is RootPath / uuid / Filename
            $Path = Join-Path $RootPath $A.uuid
    
            try {
                $Url = Get-ITBSignedUrl ($A.path + $A.filename)
                if (!(Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
                Invoke-RestMethod $Url -OutFile (Join-Path $Path $FileName)
            } catch {
                Write-Host ('Unable to download attachment: ' + $A.uuid)
            }
        }
    }
}
