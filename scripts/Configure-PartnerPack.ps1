<#
.SYNOPSIS
Configures the Azure Resources required by the PnP Partner Pack

.DESCRIPTION
This script configures all the resources required by the PnP Partner pack and prepares the local config files for deployment of the solution.

.EXAMPLE
PS C:\> .\Configure-PartnerPack.ps1 -userName "user@contoso.com" 
This will load the configuration from a config.ps1 file, prompt user for password and authenticate using "user@contoso.com" account.


.EXAMPLE
PS C:\> .\Configure-PartnerPack.ps1 -userName "user@contoso.com" -config (./custom-config.ps1)
This will load the configuration from a custom-config.ps1 file, prompt user for password and authenticate using "user@contoso.com" account.

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage="User account to be used by process.")]
    $userName,
    [Parameter(Mandatory = $false, HelpMessage="Account Password for account to be used by process.")]
    $securePassword = (Read-Host "Password" -AsSecureString),
    [Parameter(Mandatory = $false, HelpMessage="Configuration Script. This holds all the parameters required by the solution.")]
    $config = (./config.ps1 )
)

if($config.ApplicationIdentifierUri -eq $null)
{
    $config.ApplicationIdentifierUri = "https://$($config.Tenant).onmicrosoft.com/$($config.AppServiceName).azurewebsites.net".ToLower()
}

write-host "Authenticating using 3 different methods, Add-AzureAccount, Connect-AzureAD and Login-AzureRMAccount" -ForegroundColor Yellow
$cred = New-Object System.Management.Automation.PSCredential($userName, $securePassword)
Add-AzureAccount -Credential $cred
Connect-AzureAD -Credential $cred
Login-AzureRmAccount -Credential $cred

write-host "authenticated, creating resource group" -ForegroundColor Yellow
./Create-ResourceGroup.ps1 -name $config.ResourceGroupName -Location $config.Location 

write-host "resource group created, creating certificate" -ForegroundColor Yellow
if(-not (Test-PAth "./$($config.CertificateCommonName).pfx" ) -or -not (Test-PAth "./$($config.CertificateCommonName).pfx" )){
    ./Create-SelfSignedCertificate.ps1 -CommonName $config.CertificateCommonName -StartDate (get-date).AddDays(-1) -EndDate (get-date).AddYears(5) -Password $config.CertificatePassword
}

$certificateInfo =  ./Get-SelfSignedCertificateInformation.ps1 -CertificateFile $config.CertificateCommonName  #-AppClientId $config.AppClientId

write-host "Certificate created, creating storage." -ForegroundColor Yellow
$storageKeys = ./Create-StorageAccount.ps1 -name $config.StorageAccountName -ResourceGroupName  $config.ResourceGroupName -location $config.Location -SubscriptionName $config.SubscriptionName
$config.StorageAccountName = $storageKeys.StorageAccountName
Write-host "Storage Account created, creating app service " -ForegroundColor Yellow
$appCertificate = ./Create-AppService.ps1  -Location $config.Location `
                            -Name  $config.AppServiceName `
                            -ServicePlan $config.AppServicePlanName `
                            -ResourceGroupName $config.ResourceGroupName `
                            -AppServiceTier $config.AppServiceTier `
                            -CertificateCommonName $config.CertificateCommonName `
                            -CertificateFile $config.CertificateCommonName -CertificatePassword $config.CertificatePassword -CertificateThumbprint $certificateInfo.CertificateThumbprint
Write-host "App Service Created. Registering Azure AD Application" -ForegroundColor Yellow
$azureADApplication =  .\Create-AzureADApplication.ps1 -ApplicationServiceName $config.AppServiceName `
                                                            -ApplicationIdentifierUri $config.ApplicationIdentifierUri `
                                                            -CertificateFile $config.CertificateCommonName `
                                                            -Tenant $config.Tenant 

write-host "Azure AD Application added, creating infrastructure site" -ForegroundColor yellow 
./Create-InfrastructureSiteCollection.ps1 -Tenant $config.Tenant `
                                            -Owner $config.InfrastructureOwner `
                                            -AzureService $config.AppServiceName `
                                            -InfrastructureSiteUrl $config.InfrastructureSiteUrl

write-host "preparing config files" -ForegroundColor Yellow
.\Configure-Configs.ps1    -AzureStorageAccountName $config.StorageAccountName `
                            -AzureStoragePrimaryAccessKey $storageKeys.Primary `
                            -ClientId $azureADApplication.ApplicationId.Guid.ToString()  `
                            -ClientSecret $config.AppClientSecret `
                            -ADTenant "$($config.Tenant).onmicrosoft.com" `
                            -CertificateThumbprint $certificateInfo.CertificateThumbprint `
                            -InfrastructureSiteUrl $config.InfrastructureSiteUrl

write-host "config files set up, deploying governance timer jobs" -ForegroundColor Yellow
.\Provision-GovernanceTimerJobs.ps1 -Location $config.Location -AzureWebSite $config.AppServiceName     |Out-null               


write-host "Scripted configuration completed. You need to configure the required API permissions within Azure AD for Application $($config.AppServiceName) " -ForegroundColor Yellow
write-host "You might need to see what was the final configuration values, so here you go." 
write-host ($config |ConvertTo-Json) -ForegroundColor Cyan  


break
