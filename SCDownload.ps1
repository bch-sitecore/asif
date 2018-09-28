[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
Param(
  [Parameter(Position = 1, Mandatory = $true, HelpMessage = "dev.sitecore.net username")]
  [ValidateNotNullOrEmpty()]
  [Alias("Username")]
  [string]$SitecoreUsername
  ,
  [Parameter(Position = 2, Mandatory = $true, HelpMessage = "dev.sitecore.net password")]
  [ValidateNotNullOrEmpty()]
  [Alias("Password")]
  [string]$SitecorePassword
  ,
  [Parameter(Position = 3, Mandatory = $true, HelpMessage = "Source file to download")]
  [ValidateNotNullOrEmpty()]
  [string]$Uri
  ,
  [Parameter(Position = 4, Mandatory = $true, HelpMessage = "Destination path for packages")]
  [ValidateNotNullOrEmpty()]
  [string]$OutFile
  ,
  [Parameter(HelpMessage = "Allow overwrite of exiting files")]
  [switch]$AllowClobber
)

# Login to dev.sitecore.net
$loginResponse = Invoke-WebRequest "https://dev.sitecore.net/api/authorization" -Method Post -Body @{
  username = $SitecoreUsername
  password = $SitecorePassword
  rememberMe  = $true
} -SessionVariable "scSession" -UseBasicParsing -ErrorAction SilentlyContinue
If (!$loginResponse -or $loginResponse.StatusCode -ne 200) {
  Write-Error "Unable to login to dev.sitecore.net with the supplied credentials"
}

$outFile = Join-Path $Destination -ChildPath $package.FileName
If ($AllowClobber -or !(Test-Path $outFile)) {
  Invoke-WebRequest $Uri -OutFile $outFile -WebSession $scSession -UseBasicParsing
} ElseIf (!$AllowClobber) {
  Write-Error "${OutFile} zlready exists. To overwrite, use -AllowClobber"
}