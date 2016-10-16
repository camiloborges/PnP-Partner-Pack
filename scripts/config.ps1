
if($Global:config -eq $null)
{
    $Global:config = @{
        # Update with the name of your subscription.
        SubscriptionName = "Kasa Production"
        # Give a name to your new storage account. It must be lowercase!
        Tenant = "kasa"
        InfrastructureUrl ="https://kasa.sharepoint.com/sites/PnP-Partner-Pack-Infrastructure"
        InfrastructureOwner ="camilo.borges@fivep.com.au"
        StorageAccountName = "pnppartnerpackstorage669"
        Location ="australia southeast"
        ResourceGroupName="PnPPartnerPack"
        Sku ="Standard_LRS"
        AppServiceSku="Basic" 
        AppServicePlanName = "PnPPartnerPack"
        AppServiceName = "PnPPartnerPackSiteProvisioning"
        Certificate = "./FiveP.com.au"
        CertificateName = "www.fivep.com.au"
        CertificatePassword = (ConvertTo-SecureString (read-host "Please Type in your certificate password") -AsPlainText -Force)
        
    }
}
$Global:config  