[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Azure Data Center to host resource.")]
    $location,
    [Parameter(Mandatory = $true, HelpMessage="App Service Name. ")]
    $name,
    [Parameter(Mandatory = $true, HelpMessage="App Service Plan name.")]
    $servicePlan,
    [Parameter(Mandatory = $true, HelpMessage="Resource Group that holds all associated resources")]
    $resourceGroup,
    [Parameter(Mandatory = $false, HelpMessage="App Service SKU. You need at least basic for this solution")]
    $appServiceSku="Basic",     
    [Parameter(Mandatory = $true, HelpMessage="Certificate used for ssl binding.")]
    $certificateName,
    [Parameter(Mandatory = $true, HelpMessage="Password of the certificate used for ssl binding.")]
    $certificatePassword
)

New-AzureRmAppServicePlan -Location $location -ResourceGroupName $resourceGroup -Name $servicePlan -Sku $appServiceSku


New-AzureRmWebApp -Name $name `
                  -AppServicePlan $servicePlan `
                  -ResourceGroupName $resourceGroup `  
                  -Location $location `
                  -Sku $appServiceSku

$pfxPath = resolve-path "$($certificateName).pfx"
$cerPath = resolve-path "$($certificateName).cer"
New-AzureRmWebAppSSLBinding -ResourceGroupName $resourceGroupName  `
                            -WebAppName $name `  
                            -CertificateFilePath $pfxPath `
                            -CertificatePassword $certificatePassword `
                            -Name $certificateName 




$webApp = Get-AzureRmWebApp -Name $name `
                            -ResourceGroupName $resourceGroup  
$hostNames = $webApp.HostNames  
$HostNames.Add($certificateName)  

Set-AzureRmWebApp   -Name $name `
                    -ResourceGroupName $resourceGroup  `
                    -HostNames $HostNames 


Get-AzureRmWebAppCertificate -ResourceGroupName $resourceGroup

<#
New-AzureRmWebApp -Name ContosoWebApp `
                  -AppServicePlan $config.AppServicePlanName `
                  -ResourceGroupName $config.ResourceGroupName `
                  -Location $config.Location  `
                  -ASEName $config.AppServiceName `
                  -ASEResourceGroupName $config.ResourceGroupName
#>


#New-AzureRmAppService -Location $config.Location -ResourceGroupName $config.ResourceGroupName -Name $config.AppServiceName -Sku $config.AppServiceSku