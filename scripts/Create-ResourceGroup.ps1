[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true, HelpMessage="Azure Data Center to host resource.")]
    $Location,
    [Parameter(Mandatory = $true, HelpMessage="Resource Group  Name. ")]
    $Name
)

if($null -eq (Get-AzureRmResourceGroup -Name $name -Location $Location -ErrorAction 0 ) )
{
    New-AzureRmResourceGroup -Name $name -Location $Location
}