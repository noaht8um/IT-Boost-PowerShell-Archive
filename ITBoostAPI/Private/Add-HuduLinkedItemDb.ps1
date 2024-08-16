function Add-HuduImportDb {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int64]$HuduId,

        [Parameter(Mandatory = $true)]
        [int64]$ITBoost
    )
}
