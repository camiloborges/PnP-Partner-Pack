<#
.SYNOPSIS
Configures the Azure storage account 

.DESCRIPTION
This script creates an azure storage account should there be no storage accounts configured in your selected subscription

.EXAMPLE
PS C:\> .\Create-StorageAccount.ps1  -name "AzureStorageAccount" -ResourceGroupName  "PnPPartnerPack" -location "australia southeast" -subscriptionName "Contoso Production"

This will create a storage account "AzureStorageAccount" and associate it as the default storage account for subscription contoso production 


#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Azure Data Center to host resource.")]
    $Location,
    [Parameter(Mandatory = $true, HelpMessage="App Service Name. ")]
    $Name,
    [Parameter(Mandatory = $true, HelpMessage="App Service Plan name.")]
    $SubscriptionName,
    [Parameter(Mandatory = $true, HelpMessage="Resource Group that holds all associated resources")]
    $ResourceGroupName
)

 $subscription = Get-AzureSubscription -Name $SubscriptionName 

if($null -ne $subscription.CurrentStorageAccountName){
    write-host "Storage Account Already configured for this subscription. the current storage account is $($subscription.GetAccountName())" -ForegroundColor Red 
    return Get-AzureStorageKey -StorageAccountName $subscription.GetAccountName()
} 

if($null -eq (get-AzureStorageAccount -StorageAccountName $name  -ErrorAction SilentlyContinue)){
    New-AzureStorageAccount -StorageAccountName $Name.ToLower() -Location $Location | Out-Null  
    Set-AzureSubscription -CurrentStorageAccountName $Name.ToLower() -SubscriptionName $SubscriptionName
}

$result = Get-AzureStorageKey -StorageAccountName $name
return $result 
