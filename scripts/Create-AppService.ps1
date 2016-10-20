<#
.SYNOPSIS
Creates the Azure App Service that will host the PnP Partner Pack web application and web jobs

.DESCRIPTION


.EXAMPLE
PS C:\> ./Create-AppService.ps1  -Location "australia southeast" `
                            -Name  "PnPPartnerPackAppService" `
                            -ServicePlan "PnPPartnerPackAppPlan" `
                            -ResourceGroupName "PnPPartnerPack" `
                            -AppServiceTier "Basic" `
                            -CertificateCommonName "contoso.com" `
                            -CertificateFile "contoso.com" `
                            -CertificatePassword "Password1" 
                            -CertificateThumbprint "61402FFFEB61CA27FABB946193D88A7136ED2310"

#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Azure Data Center to host resource.")]
    $Location,
    [Parameter(Mandatory = $true, HelpMessage="App Service Name. ")]
    $Name,
    [Parameter(Mandatory = $true, HelpMessage="App Service Plan name.")]
    $ServicePlan,
    [Parameter(Mandatory = $true, HelpMessage="Resource Group that holds all associated resources")]
    $ResourceGroupName,
    [Parameter(Mandatory = $true, HelpMessage="Certificate used for ssl binding.")]
    $CertificateFile,
    [Parameter(Mandatory = $true, HelpMessage="Certificate Common Name.")]
    $CertificateCommonName,
    [Parameter(Mandatory = $true, HelpMessage="Password of the certificate used for ssl binding.")]
    [SecureString] $CertificatePassword,
    [Parameter(Mandatory = $true, HelpMessage="Thumbprint of certificate used for ssl binding.")]
    $CertificateThumbprint,
    [Parameter(Mandatory = $false, HelpMessage="App Service Tier. You need at least basic for this solution")]
    $AppServiceTier="Basic"     
)
if($null -eq (Get-AzureRmAppServicePlan -Name $ServicePlan -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue))
{
    New-AzureRmAppServicePlan -Location $Location -ResourceGroupName $ResourceGroupName -Name $ServicePlan -Tier $AppServiceTier
}else {
    Set-AzureRmAppServicePlan -Name $ServicePlan -Tier $AppServiceTier -ResourceGroupName $ResourceGroupName 
}

$app = (Get-AzureRmWebApp -Name $Name  -EA 0 )
if($null -eq $app -or $app.Count -eq 0){
    try{
        $app=    New-AzureRmWebApp -Name $Name  -AppServicePlan $ServicePlan -ResourceGroupName $ResourceGroupName -Location $Location  
    }catch{
        write-error "Problems creating App Service Instance." -Exception $_.Exception 
        break;
    }
}else {
if($app.ResourceGroup -ne $ResourceGroupName)
{
    write-error "Application Already exists, but in a different resource group. Stopping now" 
    break;
}elseif($app.Count -gt 1){
    write-error "Multiple Applications found with the same name. Stopping now" 
    break;
}
 
}

$hash = @{}
ForEach ($s in $app.SiteConfig.AppSettings) {
    $hash[$s.Name] = $s.Value
}
$hash["WEBSITE_LOAD_CERTIFICATES"] = "*"
#$hash
Set-AzureRMWebApp -ResourceGroupName $ResourceGroupName -Name $Name -AppSettings $hash 

if((Get-AzureRmWebAppSSLBinding -WebAppName $name -Name $CertificateCommonName -ResourceGroupName $ResourceGroupName).Count -eq 0){
    $pfxPath = resolve-path "./$($CertificateFile).pfx"
    $cerPath = resolve-path "./$($CertificateFile).cer"

$PlainTextPassword= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR( $CertificatePassword ))
write-host $PlainTextPassword

try{
    ### from https://github.com/Azure/azure-powershell/issues/2108
    ## this is a bit of a hacky way of achieving the outcome, but it does work.
    New-AzureRmWebAppSSLBinding -ResourceGroupName $ResourceGroupName  `
                                -WebAppName $Name -CertificateFilePath  $pfxPath  `
                                -CertificatePassword $PlainTextPassword  `
                                -Name $CertificateCommonName -ErrorAction Stop  -WarningAction SilentlyContinue   #Suppress the Warning on CNAME record
} catch {
        <# need to suppress the error of the SSL Binding - replace the cmdlet when changes#>
        $msg = $_
        $hostnamemsg = "Hostname '" + $DisplayName + "' does not exist."
        if($msg.tostring() -eq $hostnamemsg.tostring()) {
             $ReturnValue = $True
             }
        else {
            write-host "Encountered error while uploading the certificate to the WebApp. Error Message is $msg." -ForegroundColor Red
            }
    } 
} 
