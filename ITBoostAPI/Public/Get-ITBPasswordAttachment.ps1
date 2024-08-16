function Get-ITBPasswordAttachment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject[]]$Password
    )

    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        foreach ($P in $Password) {
            $RequestParams['Endpoint'] = "/passwords/$($Password.uuid)/attachments"
            $Attachment = Invoke-ITBAPI @RequestParams
            foreach ($A in $Attachment) {
                $A | Select-Object *,@{
                    Name       = 'path'
                    # Static Org ID...
                    Expression = { ("../uploads/652dfed2-888a-47d0-b96f-4e71b11334b5/$($P.companyUuid)/passwords/$($P.uuid)/$($P.filename)" ) }
                }
            }
        }
    }
}
