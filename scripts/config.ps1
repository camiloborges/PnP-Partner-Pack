param($force = $true)
Function New-AppSecret(){
    $length=44;
    $ascii=$NULL;
    For ($a=48;$a -le 122;$a++) {$ascii+=,[char][byte]$a }
    For ($loop=1; $loop -le $length; $loop++) {
        $TempPassword+=($ascii | GET-RANDOM)
    }
    return $TempPassword
}

if($Global:config -eq $null -or $force )
{
    $Global:config = @{
        # Update with the name of your subscription.
        SubscriptionName = "Kasa Production"
        Tenant = "kasa"
        InfrastructureSiteUrl ="https://kasa.sharepoint.com/sites/PnP-Partner-Pack-Infrastructure"
        InfrastructureOwner ="camilo.borges@fivep.com.au"
        # Give a name to your new storage account. It MUST be lowercase!
        StorageAccountName = "pnppartnerpackstorage6"
        Location ="australia southeast"
        ResourceGroupName="PnPPartnerPack6"
        Sku ="Standard_LRS"
        AppServiceTier="Basic" 
        AppServicePlanName = "PnPPartnerPack6"
        AppServiceName = "OfficeDevPnPPartnerPackSiteProvisioning6"
        CertificateCommonName = "contoso.com"
        CertificatePassword = (ConvertTo-SecureString (read-host "Please Type in your certificate password") -AsPlainText -Force)
        ApplicationIdentifierUri = $null 
        AppClientSecret=New-AppSecret #"+IXyw0OoFGGfkKQdGxD0DRM73GTAT9ykiFzipiCJUaI=" #    aIkj5T6PYBa-------=
    }
}

$Global:config  