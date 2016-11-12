set-location $PSScriptRoot
function Get-ProvisioningJob ($stream)
{
    $enc = [System.Text.Encoding]::Unicode
    $memoryStream = New-Object System.IO.MemoryStream
    $stream.CopyTo($memoryStream)
    $stream.Position = 0;
    $result = ConvertFrom-Json $enc.GetString($memoryStream.ToArray())
    $result 
}

function Get-ProvisioningJobStream($job) 
{
    $enc = [System.Text.Encoding]::Unicode
    $jobString = $job | ConvertTo-Json 
    $byteArray = $enc.GetBytes($jobString)
    $updatedStream = new-object System.IO.MemoryStream (,$byteArray)
    $updatedStream 
}

function Get-ProvisioningJobFile ($siteRelativeUrl)
{


$spfile = Get-SPOFile -SiteRelativeUrl $siteRelativeUrl  -AsFile
$spfile.Context.Load($spFile.ListItemAllFields)

$fileStream = $spfile.OpenBinaryStream()
$spFile.Context.ExecuteQuery()
    
    return @{
        Stream = $fileStream
        SPFile = $spFile
    }
}
#Connect-SPOnline "https://kasa.sharepoint.com/sites/PnP-Partner-Pack-Infrastructure"

$targetStatus = "Pending"
$jobRelativeUrl = "/PnPProvisioningJobs/a2b2e598-40ef-44e9-bcce-ed600023fde4.job"
$spJob = Get-ProvisioningJobFile $jobRelativeUrl
$job = Get-ProvisioningJob $spJob.Stream.Value
write-host $job.Status -foregroundcolor yellow
$job.Status = $targetStatus
$fields  = @{PnPProvisioningJobStatus=$targetStatus}
$job.RelativeUrl = "/sites/transitions5"

$updatedStream = Get-ProvisioningJobStream $job
$file = Add-SPOFile -FileName $spJob.SPFile.Name -Stream $updatedStream -Values $fields -Folder "PnPProvisioningJobs" 
write-host $job.Status -foregroundcolor yellow



Add-Type -Path ..\..\OfficeDevPnP.PartnerPack.SiteProvisioning\OfficeDevPnP.PartnerPack.SiteProvisioning\bin\OfficeDevPnP.PartnerPack.Infrastructure.dll 

$targetStatus = "Provisioned"
$spJob = Get-ProvisioningJobFile $jobRelativeUrl

$job = [OfficeDevPnP.PartnerPack.Infrastructure.Jobs.JobExtensions]::FromJsonStream($spJob.Stream.Value, $spJob.SPFile.ListItemAllFields["PnPProvisioningJobType"]);
$job.Status = $targetStatus
$fields  = @{PnPProvisioningJobStatus=$targetStatus}
$updatedStream = [OfficeDevPnP.PartnerPack.Infrastructure.Jobs.JobExtensions]::ToJsonStream( $job)
$file = Add-SPOFile -FileName $spJob.SPFile.Name -Stream $updatedStream -Values $fields -Folder "PnPProvisioningJobs" 

write-host $job.Status -foregroundcolor yellow



