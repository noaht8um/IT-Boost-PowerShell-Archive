[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ScriptBlock]$ScriptBlock,

    [Parameter(Mandatory = $false)]
    [hashtable]$Connection,

    [Parameter(ValueFromPipeline)]
    $ObjectsIn,

    [Parameter(Mandatory = $false)]
    [int32]$ThrottleLimit = 5
)

begin {
    if (!$Connection) {
        $Connection = @{
            XApiKey  = Read-Host -AsSecureString -Prompt 'XApiKey'
            ApiToken = Read-Host -AsSecureString -Prompt 'ApiToken'
        }
    }
    
    $ITBoostLogin = {
        Import-Module ITBoostAPI
        Connect-ITBAPI @using:Connection
    }

    $ScriptString = $ITBoostLogin.ToString() + $ScriptBlock

    $FullScriptBlock = [ScriptBlock]::Create($ScriptString)
}

process {
    $ObjectsIn | ForEach-Object -ThrottleLimit 5 -Parallel $FullScriptBlock
}
