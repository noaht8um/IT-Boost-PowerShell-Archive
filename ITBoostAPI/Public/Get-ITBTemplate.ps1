function Get-ITBTemplate {
    begin {
        $RequestParams = @{
            Method = 'Get'
        }
    }

    process {
        $RequestParams['Endpoint'] = '/templates'
        Invoke-ITBAPI @RequestParams
    }
}
