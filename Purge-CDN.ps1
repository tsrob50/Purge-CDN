
<#
.SYNOPSIS
  Azure Automation Runbook to purge files from a CDN when files are updated or deleted at the source.
.DESCRIPTION
  This script is part of a pipeline that uses Event Gird to trigger an webhook when a file is uploaded or deleted from a Storage Account.
  The Webhook passes information into the runbook including the file path.  That data is used to run the purge action against the CDN.
  Update the Parameter section and the file path.
.INPUTS
  JSON data from the Webhook
.OUTPUTS
  Errors are written to the error stream.
.NOTES
  Version:        1.0
  Author:         Travis Roberts
  Creation Date:  5/29/2019
  Purpose/Change: Initial script development
  This script provided as-is with no warrenty. Test it before you trust it.
.EXAMPLE
  See my YouTube channel at http://www.youtube.com/c/TravisRoberts or https://www.Ciraltos.com for details.
#>

# Get json input from webhook

param (
    [Parameter (Mandatory = $false)]
    [object] $WebHookData
)

## Authentication ##

# Runbook must authenticate to purge content
# Connect to Azure with RunAs account
$conn = Get-AutomationConnection -Name "AzureRunAsConnection"

# Connect to Azure Automaiton
$null = Add-AzAccount `
  -ServicePrincipal `
  -TenantId $conn.TenantId `
  -ApplicationId $conn.ApplicationId `
-CertificateThumbprint $conn.CertificateThumbprint


## declarations ##

# Update parameters below
# CDN Profile name
$profileName = 'CDN_Profile'
# CND Resource Group
$resourceGroup = 'CDN_Resource_Group'
# CDN Endpoint Name
$endPointName = 'Endpoint_Name'

# Set Error Action Default
$errorDefault = $ErrorActionPreference

## Execution ##

# Convert Webhook Body to json
try {
    $requestBody = $WebHookData.requestBody | ConvertFrom-json -ErrorAction 'stop'
}
catch {
    $ErrorMessage = $_.Exception.message
    write-error ('Error converting Webhook body to json ' + $ErrorMessage)
    Break
}
# Convert requestbody to file path
# Update with your information
try {
    $ErrorActionPreference = 'stop'
    $filePath = $requestBody.data.url -replace "https://UPDATE_THIS.core.windows.net",""
}
catch {
    $ErrorMessage = $_.Exception.message
    write-error ('Error converting file path ' + $ErrorMessage)
    Break
}
finally {
    $ErrorActionPreference = $errorDefault
}
# Run the purge command against the file
try {
    Unpublish-AzCdnEndpointContent -ErrorAction 'Stop' -ProfileName $profileName -ResourceGroupName $resourceGroup `
    -EndpointName $endPointName -PurgeContent $filePath
}
catch {
    $ErrorMessage = $_.Exception.message
    write-error ('Error purging content from CDN ' + $ErrorMessage)
    Break
}