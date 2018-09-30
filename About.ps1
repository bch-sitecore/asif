[CmdletBinding()]
Param()
$ErrorActionPreference = "Stop"

$osVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").BuildLabEx
Write-Output "Server version ${osVersion}"

$psVersion = $PSVersionTable.PSVersion
Write-Output "PowerShell version ${psVersion}"

docker version

If (Test-Path env:APPVEYOR) {
  docker images microsoft/aspnet --digests
}