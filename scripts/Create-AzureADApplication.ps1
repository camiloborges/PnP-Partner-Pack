<#
.SYNOPSIS
Creates the Azure App Service that will host the PnP Partner Pack web application and web jobs

.DESCRIPTION
Creates the Azure App Service that will host the PnP Partner Pack web application and web jobs.
This also adds a Key Credential and a password credential(AppSecret) as well as register the service principal and grant permissions


.EXAMPLE
PS C:\> ./Create-AzureADApplication.ps1  -Tenant "contoso" `
                            -ApplicationServiceName  "PnPPartnerPackAppService" `
                            -ApplicationIdentifierUri "https://contoso.onmicrosoft.com/PnPPartnerPackAppService.azurewebsites.net" `
                            -CertificateFile "contoso.com" 
Adds a new Azure AD Application. Sets 
            display name to "PnPPartnerPackAppService", 
            homepage to "https://PnPPartnerPackAppService.azurewebsites.net/"


#>


[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Office 365 Tenant name.")]
    $Tenant,
    [Parameter(Mandatory = $true, HelpMessage="App ServiceName.")]
    $ApplicationServiceName,

    [Parameter(Mandatory = $true, HelpMessage="App Service Identifier Uri. ")]
    $ApplicationIdentifierUri,
  
    [Parameter(Mandatory = $true, HelpMessage="Certificate used for ssl binding.")]
    $CertificateFile

)
$homepage = "https://$ApplicationServiceName.azurewebsites.net/".ToLower()
$certificateInfo =  ./GEt-SelfSignedCertificateInformation.ps1 -CertificateFile $CertificateFile 
$app = ((Get-AzureRmADApplication) | Where-Object { $_.IdentifierUris -contains $ApplicationIdentifierUri.ToString()} )
if($null -eq $app){
    $app = New-AzureRmADApplication -DisplayName $ApplicationServiceName  -HomePage $homepage -IdentifierUris $ApplicationIdentifierUri.ToLower() -CertValue $certificateInfo.KeyCredentials.value # $.$key 
    
    New-AzureADApplicationKeyCredential -ObjectId $app.ObjectId `
                                    -CustomKeyIdentifier "PnPProvisioningCert" `
                                    -StartDate (Get-DAte).ToUniversalTime() `
                                    -EndDate (get-Date).AddYears(2) -Usage Verify `
                                    -Value $certificateInfo.KeyCredentials.value -Type AsymmetricX509Cert |Out-Null
    New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier $config.AppServiceName.Substring(0,20).ToLower() `
                                         -Value $config.AppClientSecret |Out-Null
 }
$app
Set-AzureRmADApplication -ObjectId $app.ObjectId  -ReplyUrls @($homepage.ToLower(),"https://localhost:44300/")

if($null -eq (GEt-AzureRmADServicePrincipal -SearchString $app.DisplayName)){
    Sleep -Seconds 20 
    New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId |Out-Null 

    Sleep -Seconds 5
    New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $app.ApplicationId |Out-Null

}
