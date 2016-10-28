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
    [Parameter(Mandatory = $false, HelpMessage="User account to be used by process.")]
    $userName=(Read-Host "Please type in the user account you want to use" ),
    [Parameter(Mandatory = $false, HelpMessage="Account Password for account to be used by process.")]
    $securePassword = (Read-Host "Password" -AsSecureString),
    [Parameter(Mandatory = $false, HelpMessage="Configuration Script. This holds all the parameters required by the solution.")]
    $config = (./config.ps1 )
)
function Init-Session
{
    write-host "Authenticating using 3 different methods, Add-AzureAccount, Connect-AzureAD and Login-AzureRMAccount" -ForegroundColor Yellow
    $cred = New-Object System.Management.Automation.PSCredential($userName, $securePassword)
    try{
        Add-AzureAccount -Credential $cred | Out-Null
        Connect-AzureAD -Credential $cred | Out-Null
        Login-AzureRmAccount -Credential $cred | Out-Null
    }catch {
        write-error "Couldn't authenticate to Azure." -ForegroundColor red
        throw
    }
    write-host "authenticated, now collecting some of the required values" -ForegroundColor Yellow

    $config.Tenant = (./Confirm-ParameterValue.ps1 -prompt "Confirm your Office 365 Tenant name" -value $config.Tenant)
    if($config.Tenant.Contains(".")){
        $config.Tenant =$config.Tenant.Substring(0, $config.Tenant.IndexOf(".") )
    }
    $subscriptions = Get-AzureRmSubscription | ForEach-Object{ $_.SubscriptionName} 
    $locations = GEt-AzureRMLocation | ForEach-Object {$_.DisplayName}
    $config.SubscriptionName = (./Confirm-ParameterValue.ps1 -prompt "Confirm the Azure Subscription you'll use" -value $config.SubscriptionName -options $subscriptions)
    $config.Location = (./Confirm-ParameterValue.ps1 -prompt "Confirm the Azure Location you'll are " -value $config.Location -options $locations)

    while($null -eq (Get-AzureRmSubscription -SubscriptionName $config.SubscriptionName -ErrorAction SilentlyContinue))
    {
        write-host "couldn't find a subscription with the name you provided."
        $config.SubscriptionName = (./Confirm-ParameterValue.ps1 -prompt "Confirm the Azure Subscription you'll deploy this to" -value $config.SubscriptionName)
    }

    select-azuresubscription -SubscriptionName $config.SubscriptionName
}
function CreateStorageAccount{
    $storage =  ./Create-StorageAccount.ps1 -name $config.StorageAccountName -ResourceGroupName  $config.ResourceGroupName -Location $config.Location -SubscriptionName $config.SubscriptionName -Sku $config.StorageAccountSku
    $config.StorageAccountName = $storage.Name
    $config.StorageAccountSku = $storage.Sku
    $config.StorageAccountKey = $storage.Key
}
function CreateAppService
{
    Write-host "creating app service plan" -ForegroundColor Yellow
    $plan= ./Create-AppServicePlan.ps1  -Location $config.Location `
                                        -Name  $config.AppServicePlanName `
                                        -ResourceGroupName $config.ResourceGroupName `
                                        -AppServiceTier $config.AppServiceTier 
    $config.AppServicePlanName = $plan.Name
    $config.AppServiceTier = $plan.Tier

    Write-host "creating app service " -ForegroundColor Yellow
    $appCertificate = ./Create-AppService.ps1  -Location $config.Location `
                                -Name  $config.AppServiceName `
                                -ServicePlan $config.AppServicePlanName `
                                -ResourceGroupName $config.ResourceGroupName `
                                -CertificateCommonName $config.CertificateCommonName `
                                -CertificateFile $config.CertificateCommonName `
                                -CertificatePassword $config.CertificatePassword `                                -CertificateThumbprint $config.CertificateThumbprint
}
function CreateAzureADApplication
{
    if($config.ApplicationIdentifierUri -eq $null)
    {
        $config.ApplicationIdentifierUri = "https://$($config.Tenant).onmicrosoft.com/$($config.AppServiceName).azurewebsites.net".ToLower()
    }
    $config.ApplicationIdentifierUri = (./Confirm-ParameterValue.ps1 -prompt "Confirm Azure AD Application Identifier Uri" -value $config.ApplicationIdentifierUri).ToLower()
    $azureADApplication =  .\Create-AzureADApplication.ps1 -ApplicationServiceName $config.AppServiceName `
                                                            -ApplicationIdentifierUri $config.ApplicationIdentifierUri `
                                                            -CertificateFile $config.CertificateCommonName `
                                                            -Tenant $config.Tenant 
    $config.AzureADApplicationId = $azureADApplication.ApplicationId.Guid.ToString()
}
function CreateInfrastructureSiteCollection 
{
    $config.InfrastructureSiteOwner = ./Confirm-ParameterValue.ps1 -prompt "Confirm Infrastructure Site Collection owner" -value $username 
    $config.InfrastructureSiteUrl = ./Confirm-ParameterValue.ps1 -prompt "Confirm Infrastructure Site Collection Url" -value $config.InfrastructureSiteUrl
    $office365Creds =  New-Object System.Management.Automation.PSCredential($UserName,$securePassword);
    ./Create-InfrastructureSiteCollection.ps1 -Tenant $config.Tenant `
                                                -Owner $config.InfrastructureSiteOwner `
                                                -AzureService $config.AppServiceName `
                                                -InfrastructureSiteUrl $config.InfrastructureSiteUrl `
                                                -Credentials  $office365Creds
}
function CreateSelfSignedCertificate
{
    $config.CertificateCommonName = ./Confirm-ParameterValue.ps1 -prompt "Confirm your Certificate common name" -value $config.CertificateCommonName
    $config.CertificatePassword = ./Confirm-ParameterValue.ps1 -prompt "Confirm your Certificate Password" -value $config.CertificatePassword
  #  if(-not (Test-PAth "./$($config.CertificateCommonName).pfx" ) -or -not (Test-PAth "./$($config.CertificateCommonName).pfx" )){
        $certificate = ./Create-SelfSignedCertificate.ps1 -CommonName $config.CertificateCommonName -StartDate (get-date).AddDays(-1) -EndDate (get-date).AddYears(5) -Password $config.CertificatePassword
   # }
    $certificateInfo =  ./Get-SelfSignedCertificateInformation.ps1 -CertificateFile $config.CertificateCommonName  
    $config.CertificateThumbprint = $certificateInfo.CertificateThumbprint
}
function ConfigureConfigs{

    write-host "preparing config files" -ForegroundColor Yellow
    .\Configure-Configs.ps1    -AzureStorageAccountName $config.StorageAccountName `
                                -AzureStoragePrimaryAccessKey $config.StorageAccountKey `
                                -ClientId $config.AzureADApplicationId  `
                                -ClientSecret $config.AppClientSecret `
                                -ADTenant "$($config.Tenant).onmicrosoft.com" `
                                -CertificateThumbprint $config.CertificateThumbprint `
                                -InfrastructureSiteUrl $config.InfrastructureSiteUrl


}
Init-Session

$config.ResourceGroupName = ./Create-ResourceGroup.ps1 -name $config.ResourceGroupName -Location $config.Location 

CreateSelfSignedCertificate
CreateStorageAccount 
CreateAppService
CreateAzureADApplication 
CreateInfrastructureSiteCollection 

ConfigureConfigs

.\Provision-GovernanceTimerJobs.ps1 -Location $config.Location -AzureWebSite $config.AppServiceName     |Out-null               

write-host "Scripted configuration completed. You need to configure the required API permissions within Azure AD for Application $($config.AppServiceName) " -ForegroundColor Yellow
write-host "You might need to see what was the final configuration values, so here you go." 
write-host ($config |ConvertTo-Json) -ForegroundColor Cyan  
break
