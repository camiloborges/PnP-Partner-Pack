#Define the storage account and context.
$StorageAccountName = "pnppartnerpackstorage9"
$StorageAccountKey = "cnEqDoelDLZG++eHLI1Bp5BwK965/fotTrx5qN4/OClLEZ6Kn9euG2XeVrCohSDQOR0ABm4i3IEPR4YV7ty7+A=="
#$ContainerName = "yourcontainername"
#$BlobName = "yourblobname"
$Ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
$Ct