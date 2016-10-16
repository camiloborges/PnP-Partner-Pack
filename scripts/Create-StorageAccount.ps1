
<## Update with the name of your subscription.
$SubscriptionName = "Kasa Production"

# Give a name to your new storage account. It must be lowercase!
$StorageAccountName = "PnPPartnerPackStorage"
$location ="australia southeast"
$resourceGroupName="PnPPartnerPack"
$sku ="Standard_LRS"
#>
param 

$config = (./configs.ps1)
Add-AzureAccount
# Set a default Azure subscription.
Select-AzureRMSubscription -SubscriptionName $SubscriptionName 
# Create a new storage account.
New-AzureStorageAccount –StorageAccountName $StorageAccountName.ToLower() -Location $Location 
# Set a default storage account.
Set-AzureSubscription -CurrentStorageAccountName $StorageAccountName.ToLower() -SubscriptionName $SubscriptionName


$result = Get-AzureStorageKey -StorageAccountName $config.StorageAccountName
return $result 
