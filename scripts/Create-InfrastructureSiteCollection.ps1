[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Enter the name of your tenant, e.g. 'contoso'")]
    [String]
    $tenant, 
    [Parameter(Mandatory = $true, HelpMessage="Enter the name of site collection owner, e.g. 'admin@contoso.com'")]
    [String]
    $owner,
    [Parameter(Mandatory = $true, HelpMessage="Enter the name of site collection owner, e.g. 'admin@contoso.com'")]
    [String]
    $azureService 
)

Write-Host "Creating Infrasctrural Site collection. It will wait until it is finished"
$job  = Start-Job { 
    Connect-SPOnline "https://$tenant-admin.sharepoint.com/"
    New-SPOTenantSite -Title "PnP Partner Pack - Infrastructural Site" -Url "https://$tenant.sharepoint.com/sites/PnP-Partner-Pack-Infrastructure" -Owner $owner -Lcid 1033 -Template "STS#0" -TimeZone 4 -Wait #-RemoveDeletedSite
}
while ($job.JobStateInfo -eq 'Running'){
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5 
}
Write-Host "." -NoNewline

Write-Host "Importing Site Artifacts"
.\Provision-InfrastructureSiteArtifacts.ps1 -InfrastructureSiteUrl https://$tenant.sharepoint.com/sites/pnp-partner-pack-infrastructure -AzureWebSiteUrl "http://$($azureService).azurewebsites.net)"
Write-Host "Infrastructure Site Created. Url https://$tenant.sharepoint.com/sites/PnP-Partner-Pack-Infrastructure"