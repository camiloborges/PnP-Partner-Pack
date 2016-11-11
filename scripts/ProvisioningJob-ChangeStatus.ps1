Add-Type -Path ..\OfficeDevPnP.PartnerPack.SiteProvisioning\OfficeDevPnP.PartnerPack.SiteProvisioning\bin\OfficeDevPnP.PartnerPack.Infrastructure.dll 
function Get-ProvisioningJob ($stream)
{
    $memoryStream = New-Object System.IO.MemoryStream
    $stream.CopyTo($memoryStream)
     $stream.Position = 0;
    $enc = [System.Text.Encoding]::Unicode

    $job = ConvertFrom-Json $enc.GetString($memoryStream.ToArray())
    $job 
}

function Get-ProvisioningJobStream($job) 
{
    $jobString = $job | ConvertTo-Json 
    $byteArray = $enc.GetBytes($jobString)
    $updatedStream = new-object System.IO.MemoryStream (,$byteArray)
    $updatedStream 
}

#/PnP-Partner-Pack-Infrastructure
$spfile = Get-SPOFile -SiteRelativeUrl "/PnPProvisioningJobs/39132b5e-0024-4ea5-865b-5f0cea4bc66e.job" -AsFile
$spfile.Context.Load($spFile.ListItemAllFields)

$fileStream = $spfile.OpenBinaryStream()
$spFile.Context.ExecuteQuery()


$job = [OfficeDevPnP.PartnerPack.Infrastructure.Jobs.JobExtensions]::FromJsonStream($fileStream.Value, $spFile.ListItemAllFields["PnPProvisioningJobType"]);
$job.Status = "Pending"
$fields  = @{PnPProvisioningJobStatus="Pending"}
$updatedStream = [OfficeDevPnP.PartnerPack.Infrastructure.Jobs.JobExtensions]::ToJsonStream( $job)

Add-SPOFile -FileName $spFile.Name -Stream $updatedStream -Values $fields -Folder "PnPProvisioningJobs"

