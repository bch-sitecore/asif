[CmdletBinding()]
Param()
$ErrorActionPreference = "Stop"

$osVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").BuildLabEx
Write-Output "Server version ${osVersion}"

$psVersion = $PSVersionTable.PSVersion
Write-Output "PowerShell version ${psVersion}"

docker version
docker images microsoft/aspnet --digests

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

Write-Output "Setup complete."