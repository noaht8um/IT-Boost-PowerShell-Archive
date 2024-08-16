function Get-ITBCompany {
    $Body = @{ pageSize = 1000 }

    $RequestParams = @{
        Endpoint = '/companies'
        Method   = 'Get'
        Body     = $Body
    }

    $Response = Invoke-ITBAPI @RequestParams

    return $Response
}