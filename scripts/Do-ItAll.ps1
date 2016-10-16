
$config = (./configs.ps1 )

./Create-InfrastructureSiteCollection.ps1 -tenant $config.Tenant -owner $config.owner -azureService $config.AppServiceName

./Create-SelfSignedCertificate.ps1 -CommonName $config.CertificateName -StartDate (get-date) -EndDate (get-date).AddYears(5) -Password $config.Password
./Create-StorageAccount.ps1 -CommonName $config.CertificateName -StartDate (get-date) -EndDate (get-date).AddYears(5) -Password $config.Password
./Create-AppService.ps1 -config $config
#Get-AzureStorageKey "pnppartnerpackstorage669"