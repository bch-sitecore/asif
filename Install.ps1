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
)

Write-Output "Updating NuGet package provider"
Install-PackageProvider -Name "NuGet" -Force

Write-Output "Installing necessary module(s)"
@(
  @{ Name = "Pester";           MinimumVersion = [version]"4.4" }
  @{ Name = "PSScriptAnalyzer"; MinimumVersion = [version]"1.17" }
  @{ Name = "PowerShellGet";    MinimumVersion = [version]"1.6" }
) | ForEach-Object {
  $moduleArgs = $_
  $moduleName = $moduleArgs.Name

  Write-Output "Checking for ${moduleName}"
  $existing = Get-InstalledModule @moduleArgs -ErrorAction SilentlyContinue
  If (!$existing) {
    Write-Output "Installing/Importing ${moduleName}"
    Install-Module @moduleArgs -SkipPublisherCheck -Force
    Import-Module @moduleArgs
  }
}

# powerShellGet is shipped with PS, but as an old version. Updating the module doesn't upgrade nuget. So,
# just have to do this manually (but only if NuGet isn't already readily available via $env:Path)
Write-Output "Checking for NuGet"
If ($null -eq (Get-Command "nuget.exe" -ErrorAction SilentlyContinue)) {
  $nuget = Join-Path $env:LOCALAPPDATA -ChildPath "Microsoft\Windows\PowerShell\PowerShellGet\nuget.exe"
  If (!(Test-Path $nuget)) {
    Write-Output "Downloading NuGet"
    Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nuget -UseBasicParsing
  }
}

$resx = Join-Path $PSScriptRoot -ChildPath "resourcefiles"
$scDev = "https://dev.sitecore.net"
$scMkt = "https://marketplace.sitecore.net"
$nuget = "https://www.nuget.org/api/v2"
$scFiles = @{
  "${scDev}/~/media/F53E9734518E47EF892AD40A333B9426.ashx" = "${resx}\Sitecore 9.0.2 rev. 180604 (WDP XP0 packages).zip"
  "${scDev}/~/media/F374366CA5C649C99B09D35D5EF1BFCE.ashx" = "${resx}\Sitecore.Commerce.2018.07-2.2.126.zip"
  "${scDev}/~/media/1FF242BE683E4DE989925F74B78978FC.ashx" = "${resx}\Sitecore Experience Accelerator 1.7.1 rev. 180604 for 9.0.zip"
  "${scMkt}/services/~/download/3D2CADDAB4A34CEFB1CFD3DD86D198D5.ashx" = "${resx}\Sitecore PowerShell Extensions-4.7.2 for Sitecore 8.zip"
  "${nuget}/package/MSBuild.Microsoft.VisualStudio.Web.targets/14.0.0.3" = "${resx}\MSBuild.Microsoft.VisualStudio.Web.targets.zip"
}

If (!(Test-Path $resx)) {
  Write-Output "Creating ${resx}"
  New-Item $resx -ItemType Directory | Out-Null
}

Write-Output "Logging into dev.sitecore.net"
$loginResponse = Invoke-WebRequest "${scDev}/api/authorization" -Method Post -Body @{
  username = $SitecoreUsername
  password = $SitecorePassword
  rememberMe  = $true
} -SessionVariable "scSession" -UseBasicParsing -ErrorAction SilentlyContinue
If (!$loginResponse -or $loginResponse.StatusCode -ne 200) {
  Write-Error "Unable to login to dev.sitecore.net with the supplied credentials"
}

Write-Output "Downloading packages"
$scFiles.GetEnumerator() | ForEach-Object {
  $uri = $_.Key
  $outFile = $_.Value

  If (!(Test-Path $outFile)) {
    Write-Output "* ${outFile} <= ${uri}"
    Invoke-WebRequest $uri -OutFile $outFile -WebSession $scSession -UseBasicParsing
  } ElseIf (!$AllowClobber) {
    Write-Information "* ${outFile} <= exists"
  }
}