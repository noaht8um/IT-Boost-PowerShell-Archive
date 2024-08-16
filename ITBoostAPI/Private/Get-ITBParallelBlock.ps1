function Get-ITBParallelBlock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$ScriptBlock
    )

    begin { 
        $ITBoostLogin = {
            Import-Module ITBoostAPI
            Connect-ITBAPI -XApiKey $using:Script:ITBXApiKey -ApiToken $using:Script:ITBApiToken
        }

        $ScriptString = $ITBoostLogin.ToString() + $ScriptBlock
    }

    process {
        $FullScriptBlock = [ScriptBlock]::Create($ScriptString)
    }

    end {
        return $FullScriptBlock
    }
}